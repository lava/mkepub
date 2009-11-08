# A simple grabber for the project gutenberg-DE texts
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
	@@YAML_OUTDIR = "yaml/"

	def initialize
		Dir.mkdir(@@YAML_OUTDIR) if(!File.exist? @@YAML_OUTDIR)
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
			#convert to unicode and strip unwanted html tags
			text = text.encode("UTF-8").gsub(/<\/?a.*?>/, "").gsub(/<hr.*?\/>/, "<hr />").add_html_header(book.title).add_html_footer
			puts "Currently at chapter #{chapter}, #{name}"
			book.add_chapter(chapter, name, text)

			chapter += 1
		end

		puts "Grabbing successful. Saving raw text..."
		save_as_yaml(book)

		return book
	end

	def save_as_yaml(book)
		outdir = @@YAML_OUTDIR + "/" + book.title + "/"
		Dir.mkdir(outdir) if( !File.exist? outdir )

		File.open(outdir + "book.yaml" , "w") do |f|
			YAML.dump( book, f )
		end

		puts "YAML dump was saved in #{outdir}."
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

class String
	def add_html_header(title)
		s = <<-EOS
<?xml version='1.0' encoding='utf-8'?>
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en-US">
<head><title>#{title}</title></head>
<body>
		EOS

		return s + self
	end

	def add_html_footer
		return self + "\n</body>\n</html>"
	end
end

