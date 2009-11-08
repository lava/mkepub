#!/usr/bin/ruby

require 'grabber/gutenberg-DE'
require 'assembly/epub'

grabber = GutenbergGrabber.new
book = grabber.grab(455) #hardcoding values ftw

assembler = Epub.new(book)
assembler.write_to_dir("raw-epub/karamazov/")
