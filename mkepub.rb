#!/usr/bin/ruby1.9
# encoding: UTF-8

require 'yaml'
require 'grabber/gutenberg-DE'
require 'assembly/epub'

#grabber = GutenbergGrabber.new
#book = grabber.grab(457) #hardcoding values ftw
book = YAML.load_file("raw-text/gutenberg-DE/Die Brüder Karamasow/book.yaml")
assembler = Epub.new(book)
assembler.write_to_dir("raw-epub/karamasow/")
