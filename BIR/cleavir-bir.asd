(cl:in-package #:asdf-user)

(defsystem :cleavir-bir
  :depends-on (:cleavir-primop :cleavir-set :cleavir-attributes
                               :cleavir-conditions)
  :components
  ((:file "packages")
   (:file "structure" :depends-on ("packages"))
   (:file "primops" :depends-on ("structure" "packages"))
   (:file "instructions" :depends-on ("primops" "structure" "packages"))
   (:file "map" :depends-on ("instructions" "structure" "packages"))
   (:file "conditions" :depends-on ("packages"))
   (:file "condition-reporters-english" :depends-on ("conditions" "packages"))
   (:file "graph-modifications"
    :depends-on ("conditions" "map" "instructions" "structure" "packages"))
   (:file "verify"
    :depends-on ("map" "instructions" "structure" "packages"))
   (:file "disassemble"
    :depends-on ("map" "instructions" "structure" "packages"))))
