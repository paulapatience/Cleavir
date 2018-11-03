(cl:in-package #:common-lisp-user)

(defpackage #:cleavir-code-utilities
  (:use #:common-lisp)
  (:export #:list-structure
           #:proper-list-p
           #:proper-list-length
           #:dotted-list-p
           #:dotted-list-length
           #:proper-or-dotted-list-length
           #:form-must-be-proper-list
           #:check-form-proper-list
           #:invalid-number-of-arguments
           #:check-argcount
           #:circular-list-p
           #:lambda-list
           #:required
           #:environment
           #:whole
           #:optionals
           #:rest-body
           #:keys
           #:allow-other-keys
           #:aux
           #:parse-ordinary-lambda-list
           #:parse-generic-function-lambda-list
           #:parse-specialized-lambda-list
           #:parse-macro-lambda-list
           #:parse-destructuring-lambda-list
           #:preprocess-lambda-list
           #:parse-deftype-lambda-list
           #:parse-defsetf-lambda-list
           #:parse-define-modify-macro-lambda-list
           #:parse-define-method-combination-arguments-lambda-list
           #:lambda-list-variables
           #:destructure-lambda-list
           #:match-lambda-list
           #:parse-macro
           #:parse-compiler-macro
           #:parse-deftype
           #:lambda-lists-congruent-p
           #:generate-congruent-lambda-list
           #:lambda-list-type-specifier
           #:canonicalize-declaration-specifiers
           #:separate-ordinary-body
           #:separate-function-body
           #:lambda-list-must-be-list
           #:lambda-list-must-not-be-circular
           #:lambda-list-must-be-proper-list
           #:lambda-list-keyword-not-allowed
           #:lambda-list-keyword-not-allowed-in-dotted-lambda-list
           #:lambda-list-too-many-parameters
           #:multiple-occurrences-of-lambda-list-keyword
           #:incorrect-keyword-order
           #:both-rest-and-body-occur-in-lambda-list
           #:rest/body-must-be-followed-by-variable
           #:atomic-lambda-list-tail-must-be-variable
           #:whole-must-be-followed-by-variable
           #:whole-must-appear-first
           #:whole-must-be-followed-by-variable
           #:environment-must-be-followed-by-variable
           #:environment-can-appear-at-most-once
           #:suspect-lambda-list-keyword
           #:malformed-specialized-required
           #:malformed-ordinary-optional
           #:malformed-defgeneric-optional
           #:malformed-destructuring-optional
           #:malformed-ordinary-key
           #:malformed-defgeneric-key
           #:malformed-destructuring-key
           #:malformed-destructuring-tree
           #:malformed-aux
           #:malformed-lambda-list-pattern
           #:required-must-be-variable))
