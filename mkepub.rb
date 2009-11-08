#!/usr/bin/ruby1.9
# encoding: UTF-8

require 'yaml'
require 'grabber/gutenberg-DE'
require 'assembly/epub'

xid = 457 #hardcoding values ftw
#grabber = GutenbergGrabber.new
#book = grabber.grab(xid) 
book = YAML.load_file("yaml/Schuld und Sühne/book.yaml")
assembler = Epub.new(book)
#assembler.write_to_dir("epub-contents/#{xid}/")
assembler.write_to_file("#{book.author} - #{book.title}.epub")
