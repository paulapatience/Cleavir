(in-package #:cleavir-ast-to-bir)

(defmethod compile-ast ((ast ast:multiple-value-prog1-ast) inserter system)
  (with-compiled-ast (rv (ast:first-form-ast ast) inserter system)
    ;; Note that there are further situations we don't need to save.
    ;; If the user of the m-v-p1 only needs fixed values, those could just be
    ;; extracted early and no saving done. We don't have that information at this
    ;; moment, so an optimization pass could rewrite it. Alternately AST-to-BIR
    ;; could be rewritten to account for this kind of context.
    (let* ((during (make-iblock inserter :name '#:mv-prog1-body))
           (de (dynamic-environment inserter))
           (save-out (make-instance 'bir:output
                       :name '#:saved-values))
           (save (make-instance 'bir:values-save
                   :inputs rv
                   :outputs (list save-out) :next (list during))))
      (setf (bir:dynamic-environment during) save)
      (terminate inserter save)
      (begin inserter during)
      (cond ((compile-sequence-for-effect (ast:form-asts ast) inserter system)
             (let* ((read-out (make-instance 'bir:output
                                :name '#:restored-values))
                    (read (make-instance 'bir:values-restore
                            :inputs (list save-out) :outputs (list read-out)))
                    (after (make-iblock inserter
                                       :name '#:mv-prog1-after
                                       :dynamic-environment de)))
               (insert inserter read)
               (terminate inserter 'bir:jump
                          :inputs () :outputs () :next (list after))
               (begin inserter after)
               (list read-out)))
            (t
             ;; the forms did not return.
             ;; This makes our saving pointless, so hypothetically we could go back
             ;; and change that stuff. But meta-evaluate should delete it.
             :no-return)))))

(defmethod compile-ast ((ast ast:multiple-value-call-ast) inserter system)
  (with-compiled-ast (callee (ast:function-form-ast ast) inserter system)
    (let ((form-asts (ast:form-asts ast)))
      (cond ((null form-asts)
             (let ((call-out (make-instance 'bir:output)))
               (insert inserter 'bir:call
                       :inputs callee
                       :outputs (list call-out))
               (list call-out)))
            ((null (rest form-asts))
             (with-compiled-ast (mvarg (first form-asts) inserter system)
               (let* ((mv-call-out (make-instance 'bir:output))
                      (collect-out (make-instance 'bir:output
                                     :name '#:collected-values))
                      (mv-block (make-iblock inserter :name '#:mv-call))
                      (collect (terminate inserter 'bir:values-collect
                                          :inputs mvarg
                                          :outputs (list collect-out)
                                          :next (list mv-block)))
                      (after (make-iblock inserter :name '#:mv-call-after)))
                 (setf (bir:dynamic-environment mv-block) collect)
                 (begin inserter mv-block)
                 (insert inserter 'bir:mv-call
                         :inputs (list (first callee) collect-out)
                         :outputs (list mv-call-out))
                 (terminate inserter 'bir:jump
                            :inputs () :outputs ()
                            :next (list after))
                 (begin inserter after)
                 (list mv-call-out))))
            (t
             (loop with orig-de = (dynamic-environment inserter)
                   for form-ast in (butlast form-asts)
                   for next = (make-iblock inserter :name '#:mv-call-temp)
                   for rv = (compile-ast form-ast inserter system)
                   for mv = (if (eq rv :no-return)
                                (return-from compile-ast :no-return)
                                rv)
                   for save-out = (make-instance 'bir:output
                                    :name '#:saved-values)
                   for save = (terminate
                               inserter 'bir:values-save
                               :inputs mv :outputs (list save-out)
                               :next (list next))
                   collect save-out into save-outs
                   do (setf (bir:dynamic-environment next) save)
                      (begin inserter next)
                   finally (let* ((last-ast (first (last form-asts)))
                                  (rv (compile-ast last-ast inserter system)))
                             (when (eq rv :no-return)
                               (return-from compile-ast :no-return))
                             (let* ((mv rv)
                                    (cout (make-instance 'bir:output))
                                    (after
                                      (make-iblock inserter
                                                   :dynamic-environment orig-de
                                                   :name '#:mv-call-after))
                                    (mv-block
                                      (make-iblock inserter :name '#:mv-call))
                                    (c (terminate
                                        inserter 'bir:values-collect
                                        :inputs (nconc save-outs mv)
                                        :outputs (list cout)
                                        :next (list mv-block)))
                                    (mvcout
                                      (make-instance 'bir:output)))
                               (setf (bir:dynamic-environment mv-block) c)
                               (begin inserter mv-block)
                               (insert inserter 'bir:mv-call
                                       :inputs (list (first callee) cout)
                                       :outputs (list mvcout))
                               (terminate inserter 'bir:jump
                                          :inputs () :outputs ()
                                          :next (list after))
                               (begin inserter after)
                               (return (list mvcout))))))))))
