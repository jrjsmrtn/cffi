;;;; -*- Mode: lisp; indent-tabs-mode: nil -*-
;;; Time-stamp: <2011-09-10 18:36:53EDT structures.lisp>
;;;
;;; strings.lisp --- Operations on foreign strings.
;;;
;;; Copyright (C) 2011, Liam M. Healy  <lhealy@common-lisp.net>
;;;
;;; Permission is hereby granted, free of charge, to any person
;;; obtaining a copy of this software and associated documentation
;;; files (the "Software"), to deal in the Software without
;;; restriction, including without limitation the rights to use, copy,
;;; modify, merge, publish, distribute, sublicense, and/or sell copies
;;; of the Software, and to permit persons to whom the Software is
;;; furnished to do so, subject to the following conditions:
;;;
;;; The above copyright notice and this permission notice shall be
;;; included in all copies or substantial portions of the Software.
;;;
;;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;;; NONINFRINGEMENT.  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
;;; HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
;;; WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
;;; DEALINGS IN THE SOFTWARE.
;;;

(in-package #:cffi)

;;; Definitions for conversion of foreign structures.

(defgeneric translate-into-foreign-memory (value type p)
  (:documentation
   "Translate the Lisp value into the foreign type, writing the answers at the pointer p."))

(defun convert-into-foreign-memory (value type ptr)
  (translate-into-foreign-memory value (parse-type type) ptr)
  ptr)

(defmethod translate-to-foreign (value (type foreign-struct-type))
  (let ((ptr (foreign-alloc type)))
    (translate-into-foreign-memory value type ptr)
    ptr))

#|
;;; Example with complex

(defcstruct (complex :class complex-type)
 (real :double)
 (imag :double))
(defmethod translate-into-foreign-memory ((value complex) (type complex-type) p)
 (with-foreign-slots ((real imag) p complex)
   (setf real (realpart value)
         imag (imagpart value))))
(defmethod translate-from-foreign (p (type complex-type))
 (with-foreign-slots ((real imag) p complex)
   (complex real imag)))
(convert-to-foreign #C(1.0d0 3.0d0) 'complex)
#.(SB-SYS:INT-SAP #X0063D430)
(convert-from-foreign * 'complex)
#C(1.0d0 3.0d0)

;;; Real-and-complex:

(defcstruct (real-and-complex :class real-and-complex-type)
 (r :double)
 (c complex))
(defmethod translate-into-foreign-memory (value (type real-and-complex-type) p)
  (setf (foreign-slot-value p 'real-and-complex 'r) (first value))
  (convert-into-foreign-memory
   (second value)
   'complex
   (foreign-slot-pointer p 'real-and-complex 'c)))
(defmethod translate-from-foreign (p (type real-and-complex-type))
 (with-foreign-slots ((r c) p real-and-complex)
   (list r c)))
(convert-to-foreign '(7.0d0 #C(2.0d0 3.0d0)) 'real-and-complex)
#.(SB-SYS:INT-SAP #X0063D450)
(convert-from-foreign * 'real-and-complex)
(7.0d0 #C(2.0d0 3.0d0))

|#


#|
(defmacro define-structure-conversion
    (value-symbol type lisp-class slot-names to-form from-form &optional (struct-name type))
  "Define the functions necessary to convert to and from a foreign structure.  The to-form sets each of the foreign slots in succession, assume the foreign object exists.  The from-form creates the Lisp object, making it with the correct value by reference to foreign slots."
  `(flet ((map-slots (fn val)
            (maphash
             (lambda (name slot-struct)
               (funcall fn (foreign-slot-value val ',type name) (slot-type slot-struct)))
             (slots (follow-typedefs (parse-type ',type))))))
     ;; Convert this to a separate function so it doesn't have to be recomputed on the fly each time.
     (defmethod translate-to-foreign ((,value-symbol ,lisp-class) (type ,type))
       (let ((p (foreign-alloc ',struct-name)))
         ;;(map-slots #'translate-to-foreign ,value-symbol) ; recursive translation of slots
         (with-foreign-slots (,slot-names p ,struct-name)
           ,to-form)
         (values p t))) ; second value is passed to FREE-TRANSLATED-OBJECT
     (defmethod free-translated-object (,value-symbol (p ,type) freep)
       (when freep
         ;; Is this redundant?
         (map-slots #'free-translated-object value) ; recursively free slots
         (foreign-free ,value-symbol)))
     (defmethod translate-from-foreign (,value-symbol (type ,type))
       (with-foreign-slots (,slot-names ,value-symbol ,struct-name)
         ,from-form))))
|#


