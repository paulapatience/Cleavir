(in-package #:cleavir-bir-transformations)

;;; Given a function, return a set of all functions that enclose
;;; the function, directly or not.
(defun ancestor-functions (function)
  (let ((result (cleavir-set:empty-set)))
    (labels ((aux (enclose)
               (let ((f (cleavir-bir:function enclose)))
                 (cleavir-set:nadjoinf result f)
                 (cleavir-set:mapset nil #'aux (cleavir-bir:encloses f)))))
      (cleavir-set:mapset nil #'aux (cleavir-bir:encloses function))
      result)))

;;; Fill out the OWNER and EXTENT of all variables.
(defun analyze-variables (all-functions)
  (cleavir-set:doset (funct all-functions (values))
    (let (;; A set of all variables accessed by this function's ancestors.
          (parent-variables
            (let ((pv (cleavir-set:empty-set)))
              (cleavir-set:doset (ancestor (ancestor-functions funct))
                (cleavir-set:doset (variable (cleavir-bir:variables ancestor))
                  (cleavir-set:nadjoinf pv variable)))
              pv)))
      (cleavir-set:doset (variable (cleavir-bir:variables funct))
        (if (cleavir-set:presentp variable parent-variables)
            ;; Present in a parent, so it's definitely shared.
            (setf (cleavir-bir:extent variable) :indefinite)
            (ecase (cleavir-bir:extent variable)
              ;; Not in a parent, so it's ours. It could be in a child, in
              ;; which case the child will set it to :indefinite above.
              (:unanalyzed
               (setf (cleavir-bir:owner variable) funct
                     (cleavir-bir:extent variable) :local))
              ;; Some other function has this variable, but we're not a
              ;; parent of that function and it's not a parent of us.
              ;; This should not be possible. (FIXME: Error message.)
              ;; Calling analyze-variables on the same IR twice might do it.
              (:local (error "???"))
              ;; Some other function has already noted this variable is
              ;; indefinite - presumably a child.
              ;; NOTE: We could skip the presentp in this case
              (:indefinite)))))))

(defun closed-over-predicate (function)
  (lambda (variable)
    (and (not (eq (cleavir-bir:extent variable) :local))
         (not (eq (cleavir-bir:owner variable) function)))))

(defun mark-enclose-recursively (variables enclose)
  (let* ((owner (cleavir-bir:function enclose))
         (parents (cleavir-bir:encloses owner))
         (nparents (cleavir-set:size parents)))
    ;; mark the enclose and function
    (cleavir-set:nunionf (cleavir-bir:variables enclose) variables)
    (cleavir-set:nunionf (cleavir-bir:variables owner) variables)
    ;; Remove any variables the current function owns
    ;; and while we're at it, update the variables' enclose sets
    (cleavir-set:doset (v variables)
      (cleavir-set:nadjoinf (cleavir-bir:encloses v) enclose)
      (when (eq (cleavir-bir:owner v) owner)
        (cleavir-set:nremovef variables v)))
    (cond (;; no more variables: nothing left to do
           (cleavir-set:empty-set-p variables))
          ((zerop nparents)) ; at the top: nothing left to do
          ((= nparents 1) ; only one parent, so the set can be destroyed
           (cleavir-set:doset (p parents)
             (mark-enclose-recursively variables p)))
          (t ; have to copy the set. (NOTE: We could skip one copy.)
           (cleavir-set:doset (p parents)
             (mark-enclose-recursively
              (cleavir-set:copy-set variables) p))))))

;;; Augment each enclose instruction with the set of variables that need to be
;;; closed over. Augment each function's variable set with any variables that
;;; need to be added for the encloses. Precondition: analyze-variables has run.
(defun transmit-variables (all-functions)
  (cleavir-set:doset (funct all-functions (values))
    (let ((closed (cleavir-set:filter
                   (closed-over-predicate funct)
                   (cleavir-bir:variables funct)))
          (encloses (cleavir-bir:encloses funct)))
      (if (= (cleavir-set:size encloses) 1)
          ;; only one node, so we can destroy the set
          (cleavir-set:doset (enclose encloses)
            (mark-enclose-recursively closed enclose))
          (cleavir-set:doset (enclose encloses)
            (mark-enclose-recursively (cleavir-set:copy-set closed)
                                      enclose))))))

(defun process-captured-variables (ir)
  (let ((af (cleavir-bir:all-functions ir)))
    (analyze-variables af)
    (transmit-variables af)))