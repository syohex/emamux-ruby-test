#!/bin/sh

rm -f emamux-ruby-test.elc

carton exec emacs -nw -Q --directory $PWD --eval "(progn (require 'emamux-ruby-test) (global-emamux-ruby-test-mode))" $@
