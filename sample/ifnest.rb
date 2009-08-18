#! /usr/local/bin/ruby

require "./fast-html-template.rb"
tmpl = HTML::Template.new("./ifnest.html")
tmpl.param({'one' => { 'hoge' => 'ほげほげ', 'two' => {'hoge' => 'complete'}}}) 
print "Content-Type: text/html\n\n"
print tmpl.output

#---------------------------------------------------
#Copyright (C) 2005 Community Engine Inc. All rights reserved.
#Author : ede
#---------------------------------------------------