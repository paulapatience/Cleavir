(cl:in-package #:common-lisp-user)

(defpackage #:cleavir-processor-x86-64
  (:use #:common-lisp)
  (:export #:x86-64
	   #:implementation
	   #:gprs
	   #:argument-registers
	   #:available-registers
	   #:callee-saved-register))
