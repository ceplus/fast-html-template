#! /usr/local/bin/ruby

require "./fast-html-template.rb"

tmpl = HTML::Template.new("./proc.html")

text = "character string is cut short."
proc = Proc.new{|text,string,limit,num,str|
	lim = limit.to_i
	n = num.to_i
	if (text.size>lim)
		text = text[n..(lim-1)] + string + str
	end
}
tmpl.set_proc({'CUT'=>proc})
tmpl.expand({'text'=>text, 'a' => ' ... '})

print "Content-Type: text/html\n\n"
print tmpl.output

#---------------------------------------------------
#Copyright (C) 2005 Community Engine Inc. All rights reserved.
#Author : ede
#---------------------------------------------------