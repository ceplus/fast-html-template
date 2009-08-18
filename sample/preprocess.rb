#! /usr/local/bin/ruby

require "cgi"
require "./fast-html-template.rb"

tmpl = HTML::Template.new("./preprocess.html")
tmpl.def_prep(Proc.new{|arg|CGI::escapeHTML(arg)})
tmpl.set_prep({'URL'=>Proc.new{|arg|CGI::escape(arg)}})
tmpl.param({'data1'=>'<script>alert("hello");</script>','data2'=>'html/template'})
print "Content-type: text/html\n\n"
print tmpl.output

#---------------------------------------------------
#Copyright (C) 2005 Community Engine Inc. All rights reserved.
#Author : ede
#---------------------------------------------------