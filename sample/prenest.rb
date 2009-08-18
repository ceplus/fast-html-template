#! /usr/local/bin/ruby

require "cgi"
require "./fast-html-template.rb"

tmpl = HTML::Template.new("./prenest.html")
tmpl.set_prep({'HTML'=>Proc.new{|arg|CGI::escapeHTML(arg)}})
tmpl.param({'data0'=>'<','block1'=>{'data0'=>'"','block2'=>{'data0'=>'>'}}})

print "Content-Type: text/html\n\n"
print tmpl.output

#---------------------------------------------------
#Copyright (C) 2005 Community Engine Inc. All rights reserved.
#Author : ede
#---------------------------------------------------