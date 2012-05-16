(defpackage :4image
  (:use :common-lisp :parenscript)
  (:nicknames :4i)
  (:export #:compile-4i))

(in-package :4image)

(defparameter *name*
  "//@name              4chan image enhancer")
(defparameter *description*
  "//@description       Adds image enhancements to 4chan")
(defparameter *includes*
  "//@include           http*://boards.4chan.org/*")
(defparameter *author*
  "//@author            Frebith")
(defparameter *version*
  "//@version           0.5")
(defparameter *update*
  "//@updateURL         https://raw.github.com/Frebith/4chanimage/master/4chan-image.js")
(defparameter *license*
  "//@license           MIT; http://www.opensource.org/licenses/mit-license.php")
(defparameter *MIT*
  "
/*
*Copyright (c) 2012 Frebith
*Permission is hereby granted, free of charge, to any person obtaining a copy of this software 
*and associated documentation files (the 'Software'), to deal in the Software without restriction, 
*including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
*and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do 
*so, subject to the following conditions: 
*
*The above copyright notice and this permission notice shall be included in all copies or substantial 
*portions of the Software. 
*
*THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT 
*LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN 
*NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
*WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
*SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/")

(defparameter *header*
  (format nil "~A~%~A~%~A~%~A~%~A~%~A~%~A~%~A~%~A~%"
          "// ==UserScript=="
          *name*
          *version*
          *author*
          *description*
          *license*
          *includes*
          *update*
          "// ==/UserScript=="))

(defun compile-4i (file)
  (with-open-file (out file :direction :output
                       :if-exists :supersede)
    (princ *header* out)
    (princ *MIT* out)
    (format out "~A~%"
            (ps
             ;;4image config options
             (var +image-hover+ true)
             (var +image-gif+ false)
             (var +image-preload+ false)
             (var +image-sauce+ true)
             ;;

             ;;image-sause vars
             ;;works just like 4chan-x's sauce
             ;;$1 => thumbnail url
             ;;$2 => full image url
             ;;$3 => md5 hash
             ;;$4 => current board
             ;;urls starting with `#' will be ignored
             (var +image-sauces+ ([] "http://iqdb.org/?url=$1"
                                     "http://google.com/searchbyimage?image_url=$1"
                                     "#http://tineye.com/search?url=$1"
                                     "#http://saucenao.com/search.php?db=999&url=$1"
                                     "#http://3d.iqdb.org/?url=$1"
                                     "#http://regex.info/exif.cgi?imgurl=$2"
                                     "http://imgur.com/upload?url=$2"
                                     "#http://omploader.org/upload?url1=$2"
                                     "#http://archive.foolz.us/$4/image/$3/"
                                     "#http://archive.installgentoo.net/$4/image/$3"))
             ;;

             ;;image-hover vars
             (var +update-time+ 5000)
             (var +image-x-offset+ 30)
             (var +image-border+ 0)
             (var img-cell (chain document (create-element "TD")))
             (var img-tab (chain document (create-element "DIV")))
             (chain img-tab (set-attribute "style" "display:none;position:absolute;"))
             (chain img-tab (append-child (chain
                                           (chain document (create-element "TABLE"))
                                           (append-child (chain
                                                          (chain document (create-element "TR"))
                                                          (append-child img-cell))))))
             (chain document body (append-child img-tab))
             ;;
             
             ;;track old images so we don't repeat
             (var old-images (make-array))

             ;;updates 4i every +update-time+ time [ms]
             (var update (chain (set-timeout update-images +update-time+)))
             ;;do first scan
             (update-images)

             (defun update-images ()
               ;;get all images
                                        ;(var images (chain document (get-elements-by-tag-name "img")))
               (var images (chain document (get-elements-by-class-name "fileThumb")))
               (dotimes (i (@ images 'length))
                 ;;update only new images
                 (when (= (chain old-images (index-of (chain (getprop images i) (get-attribute "href")))) -1)
                   (update-image (getprop images i) (@ (getprop images i) 'first-child))
                   ;;store
                   (chain old-images (push (chain (getprop images i) (get-attribute "href"))))))
               ;;reset timer to go off in +update-time+ time again
               (setf update (chain (set-timeout update-images +update-time+)))
               t)
             
             (defun update-image (a img)
               (when +image-sauce+
                 (setup-sauce (@ a 'parent-element 'first-child) a img))

               ;;add listeners
               (when +image-hover+
                 (chain img (add-event-listener "mouseover"
                                                (lambda (x) (image-show x this))
                                                false))
                 (chain img (add-event-listener "mousemove"
                                                (lambda (x) (image-track x))
                                                t))
                 (chain img (add-event-listener "mouseout"
                                                (lambda () (image-hide))
                                                false)))
               (when (and +image-gif+
                          (= (chain (chain a (get-attribute "href")) (index-of ".gif"))
                             (- (@ (chain a (get-attribute "href")) 'length) 4)))
                 (chain img (set-attribute "src" (chain (@ img 'parent-element) (get-attribute "href")))))

               (when +image-preload+
                 (chain img (set-attribute "src" (chain a (get-attribute "href")))))
               
               t)
             
             ;;IMAGE HOVER STUFF
             (defun image-show (event img)
               (setf (@ img-cell 'inner-h-t-m-l)
                     (+ "<img src=\""
                        (chain img parent-element (get-attribute "href"))
                        "\" border=\""
                        +image-border+
                        "\">"))
               (image-track event)
               t)

             (defun image-track (event)
               (when (@ img-cell 'inner-h-t-m-l)
                 (let* ((tip-height (/ (@ img-tab 'client-height) 2))
                        (vp-height (chain -math (min (@ document 'document-element 'client-height)
                                                     (@ document 'body 'client-height))))
                        (vp-width (chain -math (min (@ document 'document-element 'client-width)
                                                    (@ document 'body 'client-width))))
                        (vp-bottom (+ (@ window 'scroll-y) vp-height))
                        (tip-y-offset 0))
                   (setf (@ img-tab 'style 'display) "")
                   (cond
                     ((or (< (- (@ event 'page-y) tip-height)
                             (@ window 'scroll-y))
                          (> (@ img-tab 'client-height)
                             vp-height))
                      (setf tip-y-offset (@ window 'scroll-y)))
                     ((>= (+ (@ event 'page-y) tip-height) vp-bottom)
                      (setf tip-y-offset (- vp-bottom (@ img-tab 'client-height))))
                     (t
                      (setf tip-y-offset (- (@ event 'page-y) tip-height))))
                   (setf (@ img-tab 'style 'top) (+ tip-y-offset "px"))
                   (if (> (@ event 'page-x)
                          (* vp-width 0.6))
                       (progn
                         (setf (@ img-tab 'style 'right)
                               (+ (- (+ vp-width +image-x-offset+) (@ event 'page-x)) "px"))
                         (setf (@ img-tab 'style 'left) ""))
                       (progn
                         (setf (@ img-tab 'style 'left)
                               (+ (@ event 'page-x) +image-x-offset+ "px"))
                         (setf (@ img-tab 'style 'right) "")))))
               t)

             (defun image-hide ()
               (setf (@ img-tab 'style 'display) "none")
               (setf (@ img-cell 'inner-h-t-m-l) "")
               t)
             ;;

             
             ;;IMAGE-SAUCE STUFF
             (defun setup-sauce (bar a img)
               (let* ((full-url (chain a (get-attribute "href")))
                      (thumb-url (chain img (get-attribute "src")))
                      (md5 (chain img  (get-attribute "data-md5")))
                      (board (getprop (chain full-url (match (regex "/[/][a-zA-Z0-9]{1,}[/]/i"))) 0))
                      (sitename ""))
                 ;;fix board
                 (setf board (chain board (substring 1 (1- (@ board 'length)))))
                 (dolist (url +image-sauces+)
                   ;;ignore commented sauces
                   (when (/= (chain url (char-at 0)) "#")
                     ;get sitename - possible mismatch on the regex TODO
                     (setf sitename (getprop (chain url (match (regex "/[a-zA-Z0-9]{1,}[.][cinou][enors]/i"))) 0))
                     (setf sitename (chain sitename (substring 0 (- (@ sitename 'length) 3))))
                     ;fill in replacements
                     (setf url (chain url 
                                      (replace "$1" (+ "https:" thumb-url))
                                      (replace "$2" (+ "https:" full-url))
                                      (replace "$3" md5)
                                      (replace "$4" board)))
                     (setf (@ bar 'inner-h-t-m-l) (+ (@ bar 'inner-h-t-m-l)
                                                     " <a target=\"_blank\" href=\""
                                                     url
                                                     "\">["
                                                     sitename
                                                     "]</a>"))))))
             ;;

             ))));;eof
