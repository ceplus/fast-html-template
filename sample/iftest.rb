#! /usr/local/bin/ruby

require "./fast-html-template.rb"
tmpl = HTML::Template.new("./iftest.html")
tmpl.param({'true' => {}, 'false' => nil})
print "Content-Type: text/html\n\n"
print tmpl.output

#---------------------------------------------------
#Copyright (C) 2005 Community Engine Inc. All rights reserved.
#Author : ede
#---------------------------------------------------