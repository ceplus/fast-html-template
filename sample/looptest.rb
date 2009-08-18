#! /usr/local/bin/ruby

require "./fast-html-template.rb"

tmpl = HTML::Template.new("./looptest.html")

hoge = []

10000.times{ |i|
	hoge.push({'a' => i,'b' => i*2})
}

tmpl.expand({'hoge' => hoge})
print "Content-type: text/html\n\n"
print tmpl.output

#---------------------------------------------------
#Copyright (C) 2005 Community Engine Inc. All rights reserved.
#Author : ede
#---------------------------------------------------