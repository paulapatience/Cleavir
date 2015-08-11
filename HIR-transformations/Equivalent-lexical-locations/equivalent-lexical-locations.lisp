(cl:in-package #:cleavir-equivalent-lexical-locations)

(defun set-equality (set1 set2 test)
  (and (null (set-difference set1 set2 :test test))
       (null (set-difference set2 set1 :test test))))

(defun class-equality (class1 class2)
  (set-equality class1 class2 #'eq))

(defun partition-equality (partition1 partition2)
  (set-equality partition1 partition2 #'class-equality))

(defun remove-location (partition variable)
  (let ((dclass (find variable partition :test #'member)))
    (cond ((null dclass)
	   partition)
	  ((= (length dclass) 2)
	   (remove dclass partition :test #'eq))
	  (t
	   (cons (remove variable dclass :test #'eq)
		 (remove dclass partition :test #'eq))))))

(defun add-equivalence (partition defined used)
  (let ((uclass (find used partition :test #'member)))
    (if (null uclass)
	(cons (list defined used) partition)
	(cons (cons defined uclass)
	      (remove uclass partition :test #'eq)))))

(defun update-for-meet (instruction partition)
  (let ((temp partition))
    (loop for output in (cleavir-ir:outputs instruction)
	  do (setf temp (remove-location temp output)))
    (if (typep instruction 'cleavir-ir:assignment-instruction)
	(let ((input (first (cleavir-ir:inputs instruction)))
	      (output (first (cleavir-ir:outputs instruction))))
	  (if (and (typep input 'cleavir-ir:lexical-location)
		   (typep output 'cleavir-ir:lexical-location))
	      (add-equivalence temp output input)
	      temp))
	temp)))

(defun update-for-join (partition1 partition2)
  (let* ((locations1 (reduce #'append partition1 :from-end t))
	 (locations2 (reduce #'append partition2 :from-end t))
	 (common (intersection locations1 locations2 :test #'eq))
	 (p1 (loop for class in partition1
		   for stripped = (intersection class common :test #'eq)
		   when (> (length stripped) 1)
		     collect stripped))
	 (p2 (loop for class in partition2
		   for stripped = (intersection class common :test #'eq)
		   when (> (length stripped) 1)
		     collect stripped))
	 (result '()))
    (loop until (null common)
	  do (let* ((location (first common))
		    (class1 (find location p1 :test #'member))
		    (class2 (find location p2 :test #'member))
		    (intersection (intersection class1 class2 :test #'eq))
		    (diff1 (set-difference class1 intersection :test #'eq))
		    (diff2 (set-difference class2 intersection :test #'eq)))
	       (setf common (set-difference common intersection :test #'eq))
	       (setf p1 (remove class1 p1 :test #'eq))
	       (setf p2 (remove class2 p2 :test #'eq))
	       (when (> (length intersection) 1)
		 (push intersection result))
	       (when (> (length diff1) 1)
		 (push diff1 p1))
	       (when (> (length diff2) 1)
		 (push diff2 p2))))
    result))

(defun compute-equivalent-lexical-locations (initial-instruction)
  (let ((work-list (list initial-instruction))
	(before (make-hash-table :test #'eq))
	(after (make-hash-table :test #'eq)))
    (setf (gethash initial-instruction before) '())
    (loop until (null work-list)
	  do (let ((instruction (pop work-list)))
	       (setf (gethash instruction after)
		     (update-for-meet instruction (gethash instruction before)))
	       (loop for successor in (cleavir-ir:successors instruction)
		     for predecessors = (cleavir-ir:predecessors successor)
		     for join = (if (= (length predecessors) 1)
				    (gethash (first predecessors) after)
				    (reduce #'update-for-join
					    (mapcar (lambda (p)
						      (gethash p after))
						    predecessors)))
		     unless (partition-equality join (gethash successor before))
		       do (setf (gethash successor before) join)
			  (push successor work-list))))
    before))
