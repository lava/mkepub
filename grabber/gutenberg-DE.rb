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
	# always order from more specific to less specific, if applicable
	@@META_INFO_LOCATIONS = ["gb_meta", "div#gb_texte/html/head/meta"]
	@@HEADING_LOCATIONS = ["div#gb_texte/html/body/", "div#gb_texte/"]
	@@TEXT_LOCATIONS = ["div#gb_texte/html/body", "div#gb_texte"]

	def initialize
		Dir.mkdir(@@YAML_OUTDIR) if(!File.exist? @@YAML_OUTDIR)
	end

	def grab(xid, save_yaml_output = true)
		book_info = get_book_info(xid)
		book = Book.new(book_info)
		puts "Beginning grabbing xid #{xid} (title: #{book.title})"

		chapter = 1
		loop do
			url = @@BASE_URL + "&id=12&xid=#{xid}&kapitel=#{chapter}"
			doc = Hpricot(open(url))
			#project gutenberg seems to use different <hi>-heading tags for the chapters, 
			#depending on the book, so we just test every possibility
			#also, some texts have the author as a seperate heading, and some don't, so we
			#try to filter that out as well
			heading_possibilities = [1,2,3,4,5,6].map do |i|
				@@HEADING_LOCATIONS.map { |head|	
					doc.search(head + "h#{i}").find { |elem| 
						elem.get_attribute("class").nil? || elem.get_attribute("class") != "author"
					}
				}
			end
			name = heading_possibilities.flatten.find {|x| !x.nil? }

			# end of book (we kinda have to guess here, there doesnt seem to be a completely
			# deterministic criterion)
			break if name.nil?

			#cleanup html tags and fix encoding
			name = name.inner_html.gsub(/\n.*/, "").gsub(/<.*?>/, "")
			name.force_encoding("iso-8859-1")
			name = name.encode("UTF-8")

			#same for text
			text = @@TEXT_LOCATIONS.map { |text| doc.search(text).inner_html }.find {|x| x != ""}
			text.force_encoding("iso-8859-1")
			text = text.encode("UTF-8").gsub(/<\/?a.*?>/, "").gsub(/<hr.*?\/>/, "<hr />").add_html_header(book.title).add_html_footer
			puts "Currently at chapter #{chapter}, #{name}"
			book.add_chapter(chapter, name, text)

			chapter += 1
		end

		if save_yaml_output
			puts "Grabbing successful. Saving raw text..."
			save_as_yaml(book) 
		end

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
		author = "Unknown Author"
		title = "Unknown Title"
		# the place where meta-info is stored seems to vary, so
		# we have to try out the known possibilities
		@@META_INFO_LOCATIONS.each do |meta|
			if doc.at(meta + "[@name=author]")
				author = doc.at(meta + "[@name=author]").get_attribute("content").force_encoding("iso-8859-1").encode("UTF-8")
			end
			if doc.at(meta + "[@name=title]")
				title = doc.at(meta + "[@name=title]").get_attribute("content").force_encoding("iso-8859-1").encode("UTF-8")
			end
		end
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

