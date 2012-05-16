4chan image
==========

# What's it do?
- view full-image on mouse-hover (default: on)
- animate gifs in thumbs (default: off)
- image preloading (default: off)
- image sauce (default: on)
- - you can edit the sauces you want in the +image-sauce+ array
- - sauces starting with # are ignored, $1,$2,$3,$4 refer to {thumlurl,fullurl,md5,board}
- Note: All 4 of these options can be turned on/off in the 4chan-image.js file (right under the LICENSE comment)

# Building
- Download Parenscript for Common Lisp and a CL compiler of your coice (I tested with SBCL)
- download 4image.lisp
- (require :parenscript)
- (load "path/to/4image.lisp")
- (4i:compile-4i "name-of-file.js")
