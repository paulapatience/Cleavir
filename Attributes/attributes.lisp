(in-package #:cleavir-attributes)

(defclass attributes ()
  (;; Boolean flags; see flags.lisp
   (%flags :initarg :flags :initform 0 :reader flags :type (integer 0))
   ;; A list of objects that BIR-TRANSFORMATIONS uses to invoke
   ;; client-defined, function-specific transformations.
   ;; Their nature is not defined by Cleavir, except that they can be
   ;; compared with EQUAL, and that they should be externalizable if ASTs
   ;; are to be externalized.
   ;; See BIR-TRANSFORMATIONS:TRANSFORM-CALL.
   ;; FIXME: Might need some more thought on this.
   (%transforms :initarg :transforms :initform nil :reader transforms)
   ;; An list of objects that BIR-TRANSFORMATIONS uses to invoke
   ;; client-defined, function-specific type derivations.
   ;; Similar to the transforms, their nature is not defined except as
   ;; for them.
   ;; See BIR-TRANSFORMATIONS:DERIVE-RETURN-TYPE.
   ;; FIXME: Besides the more thoughts above, this might warrant a more
   ;; complex type system in order to allow combining information.
   ;; For example, (if test #'+ #'-) could still be seen to return two
   ;; floats if given a float.
   (%derivers :initarg :derivers :initform nil :reader derivers)
   ;; List of constant folders. Similar concerns to above.
   (%folds :initarg :folds :initform nil :reader folds)))

;;; We need to be able to externalize attributes for clients that externalize
;;; them as part of inline definition ASTs.
(defmethod make-load-form ((object attributes) &optional env)
  (make-load-form-saving-slots object :environment env))

(cleavir-io:define-save-info attributes
    (:flags (flags attributes))
  (:transforms (transforms attributes))
  (:derivers (derivers attributes))
  (:folds (folds attributes)))

;;; NIL means no special attributes.
(deftype attributes-designator () '(or attributes null))

(defmethod flags ((attr null)) 0)
(defmethod transforms ((attr null)) nil)
(defmethod derivers ((attr null)) nil)
(defmethod folds ((attr null)) nil)

(defun default-attributes () nil)

(defgeneric has-flag-p (attributes flag-name))

(defmethod has-flag-p ((attributes null) flag-name)
  (declare (ignore has-flag-p))
  nil)
(defmethod has-flag-p ((attributes attributes) flag-name)
  (%has-flag-p (flags attributes) flag-name))

;;; Is attributes-1 less specific than attributes-2?
(defgeneric sub-attributes-p (attributes-1 attributes-2))

(defmethod sub-attributes-p ((attr1 null) (attr2 null)) t)
(defmethod sub-attributes-p ((attr1 null) (attr2 attributes)) t)
(defmethod sub-attributes-p ((attr1 attributes) (attr2 null)) nil)
(defmethod sub-attributes-p ((attr1 attributes) (attr2 attributes))
  (and (sub-flags-p (flags attr1) (flags attr2))
       (subsetp (transforms attr1) (transforms attr2) :test #'equal)
       (subsetp (derivers attr1) (derivers attr2) :test #'equal)
       (subsetp (folds attr1) (folds attr2) :test #'equal)))

;;; Return attributes combining both inputs; the returned attributes
;;; only have a given quality if both of the inputs do. Because attributes
;;; are of function parameters, they are contravariant, and so this can be
;;; used like CL:OR types.
(defgeneric meet-attributes (attributes-1 attributes-2))
;;; Dual of the above.
(defgeneric join-attributes (attributes-1 attributes-2))

(defmethod meet-attributes ((attr1 null) (attr2 null)) attr1)
(defmethod meet-attributes ((attr1 null) (attr2 attributes)) attr1)
(defmethod meet-attributes ((attr1 attributes) (attr2 null)) attr2)
(defmethod meet-attributes ((attr1 attributes) (attr2 attributes))
  ;; Try to avoid consing.
  (cond ((sub-attributes-p attr1 attr2) attr1)
        ((sub-attributes-p attr2 attr1) attr2)
        (t (make-instance 'attributes
             :flags (meet-flags (flags attr1) (flags attr2))
             :transforms (intersection (transforms attr1)
                                       (transforms attr2) :test #'equal)
             :derivers (intersection (derivers attr1) (derivers attr2)
                                     :test #'equal)
             :folds (intersection (folds attr1) (folds attr2)
                                  :test #'equal)))))

(defmethod join-attributes ((attr1 null) (attr2 null)) attr1)
(defmethod join-attributes ((attr1 null) (attr2 attributes)) attr2)
(defmethod join-attributes ((attr1 attributes) (attr2 null)) attr1)
(defmethod join-attributes ((attr1 attributes) (attr2 attributes))
  (cond ((sub-attributes-p attr1 attr2) attr2)
        ((sub-attributes-p attr2 attr1) attr1)
        (t (make-instance 'attributes
             :flags (join-flags (flags attr1) (flags attr2))
             :transforms (union (transforms attr1) (transforms attr2)
                                :test #'equal)
             :derivers (union (derivers attr1) (derivers attr2)
                              :test #'equal)
             :folds (union (folds attr1) (folds attr2))))))
