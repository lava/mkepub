class Epub
	def initialize(book)
		@book = book
		@chapters = book.chapters.sort { |c1, c2| c1.seqno <=> c2.seqno }
		@uid = Time.now.to_i + book.title
	end

	def write_to_dir(dirname)
		dir = dirname + "/" # dont rely on the caller for this
		File.mkdir(dir) if !File.exist? dir

		#create various required files
		#1. manifest
		manifest = File.open(outdir + "manifest", "w")
		manifest << "application/epub+zip"
		manifest.close()

		#2.content.opf
		opfheader = <<-EOS
		<package unique-identifier="book-id" version="2.0">
		<metadata xmlns:dc="http://purl.org/dc/elements/1.1/"
	          xmlns:opf="http://www.idpf.org/2007/opf/">
		<dc:identifier id="book-id">#{@uid}</dc:identifier>
		<dc:title>#{@book.title}</dc:title>
		<dc:creator opf:role="aut">#{@book.author}</dc:creator>
		<dc:language>#{@book.lang}</dc:language>
		<dc:date>#{@book.year}</dc:date>
		</metadata>

		<manifest>
		<item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml" />
		EOS

		items = @chapters.inject("") { |s, c| 
			s + "<item id=\"chapter#{c.seqno}\" href=\"content/chapter#{c.seqno}.html\" media-type=\"application/xhtml+xml\"/>\n"
		} + "</manifest>"

		spine = @chapters.inject("<spine toc=\"ncx\">\n") { |s, c|
			s + "itemref idref=\"chapter#{c.seqno}\" />\n"
		} + "</spine>\n\n" 

		opf = File.open(dir + "content.opf", "w")
		opf << opfheader
		opf << items
		opf << spine
		opf << "</package>"
		opf.close()

		#3. meta-inf/container.xml
		container = File.open(dir + "meta-inf/container.xml", "w")
		container << '<container version="1.0"><rootfiles><rootfile full-path="content.opf" media-type="application/oebps-package+xml"/></rootfiles></container>'
		container.close()

		#4. toc.ncx
		toc_header = <<-EOS
		<ncx version="2005-1">
		<head>
		<meta name="dtb:uid" content="#{@uid}"/>
		<meta name="dtb:depth" content="1"/>
		<meta name="dtb:totalPageCount" content="0"/>
		<meta name="dtb:maxPageNumber" content="0"/>
		</head>
		<docTitle>
		<text>#{@book.title}</text>
		</docTitle>
		EOS

		toc_entries = @chapters.inject("<navMap>\n") {|s, c|
			s + "<navPoint id=\"chapter#{c.seqno} class=\"chapter\" playOrder=\"#{c.seqno}\">\n<navLabel>\n<text>#{c.title}</text>\n</navLabel>\n<content src=\"content/chapter#{c.seqno}.html\" />\n</navPoint>\n"
		} + "</navMap>\n"

		toc = File.open(dir + "toc.ncx", "w")
		toc << toc_header
		toc << toc_entries + "</ncx>"
		toc.close()

		#5. finally, the html-files for each chapter
		@chapter.each do |chapter|
			n = chapter.seqno
			f = File.open(dir + "content/chapter#{n}.html", "w")
			f << chapter.text
			f.close()
		end

		puts "Successfully wrote .epub file structure to #{dir}."
	end

	def write_to_file(filename)
		name = filename.strip(".epub") + ".epub"
		Dir.rmdir("tmp") if File.directory? "tmp"
		File.mkdir("tmp")
		write_to_dir("tmp")
		# todo: zip dir and rename to .epub
	end
end
