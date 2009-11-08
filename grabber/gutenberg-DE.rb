# A simple grabber for the project gutenberg-DE texts
# takes as input the xid of the book you want to grab.
# Disclaimer: only tested with xid's 455 and 457, will contain
# lots of bugs

require 'rubygems'
Gem.activate "hpricot" # some strange ubuntu-rubygems1.9-wtf
require 'hpricot'
require 'open-uri'
require 'yaml'

require 'common/book'


class GutenbergGrabber
	@@BASE_URL = "http://gutenberg.spiegel.de/?"
	@@BASE_OUTDIR = "raw-text/gutenberg-DE/"

	def initialize
		Dir.mkdir(@@BASE_OUTDIR) if(!File.exist? @@BASE_OUTDIR)
	end

	def grab(xid)
		book_info = get_book_info(xid)
		book = Book.new(book_info)
		puts "Beginning grabbing xid #{xid} (title: #{book.title})"

		chapter = 1
		loop do
			url = @@BASE_URL + "&id=12&xid=#{xid}&kapitel=#{chapter}"
			doc = Hpricot(open(url))
			name = doc.search("div#gb_texte/h3").first
			break if name.nil?

			#cleanup
			name = name.inner_html.gsub(/\n.*/, "").gsub(/<.*?>/, "")
			name.force_encoding("iso-8859-1")
			name = name.encode("UTF-8")
			text = doc.search("div#gb_texte").inner_html
			text.force_encoding("iso-8859-1")
			text = text.encode("UTF-8")
			puts "Currently at chapter #{chapter}, #{name}"
			book.add_chapter(chapter, name, text)

			chapter += 1
		end

		puts "Grabbing successful. Saving raw text..."
		save_as_yaml(book)

		return book
	end

	def save_as_yaml(book)
		outdir = @@BASE_OUTDIR + "/" + book.title + "/"
		Dir.mkdir(outdir) if( !File.exist? outdir )

		File.open(outdir + "book.yaml" , "w") do |f|
			YAML.dump( book, f )
		end

		puts "Raw text was saved in #{outdir}."
	end

	def get_book_info(xid)
		url = @@BASE_URL + "&id=5&xid=#{xid}&kapitel=1"
		doc = Hpricot(open(url))
		author = doc.at("gb_meta[@name=author]").get_attribute("content").force_encoding("iso-8859-1").encode("UTF-8")
		title = doc.at("gb_meta[@name=title]").get_attribute("content").force_encoding("iso-8859-1").encode("UTF-8")
		# sadly, the year isn't that easy to find out...best 
		# approach would probably be finding the author id,
		# going to the author page and searching for the title there
		return {:author => author, :title => title, :lang => "de"}
	end
end

