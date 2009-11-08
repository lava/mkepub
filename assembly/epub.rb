Gem.activate "rubyzip" # yes, my rubygems is horribly broken
require 'zip/zip'

class Epub
	def initialize(book)
		@book = book
		@chapters = book.chapters.sort { |c1, c2| c1.seqno <=> c2.seqno }
		@uid = Time.now.to_i.to_s 
	end

	def write_to_dir(dirname)
		dir = dirname + "/" # dont rely on the caller for this
		Dir.mkdir(dir) if !File.exist? dir

		#create various required files and directorys
		#0. directorys
		Dir.mkdir(dir + "content")
		Dir.mkdir(dir + "META-INF")

		#1. manifest
		mimetype = File.open(dir + "mimetype", "w")
		mimetype << "application/epub+zip"
		mimetype.close()

		#2.content.opf
		opfheader = <<-EOS
<?xml version='1.0' encoding='utf-8'?>
		<package xmlns="http://www.idpf.org/2007/opf" unique-identifier="uuid" version="2.0">
		<metadata xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:opf="http://www.idpf.org/2007/opf">
		<dc:identifier id="uuid">#{@uid}</dc:identifier>
		<dc:title>#{@book.title}</dc:title>
		<dc:creator opf:role="aut">#{@book.author}</dc:creator>
		<dc:language>#{@book.lang}</dc:language>
		<dc:date opf:event="release">#{@book.year}</dc:date>
		</metadata>

		<manifest>
		<item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml" />
		EOS

		items = @chapters.inject("") { |s, c| 
			s + "<item id=\"chapter#{c.seqno}\" href=\"content/chapter#{c.seqno}.html\" media-type=\"application/xhtml+xml\"/>\n"
		} + "</manifest>"

		spine = @chapters.inject("<spine toc=\"ncx\">\n") { |s, c|
			s + "<itemref idref=\"chapter#{c.seqno}\" />\n"
		} + "</spine>\n\n" 

		opf = File.open(dir + "content.opf", "w")
		opf << opfheader
		opf << items
		opf << spine
		opf << "</package>"
		opf.close()

		#3. meta-inf/container.xml
		container = File.open(dir + "META-INF/container.xml", "w")
		container << '<?xml version="1.0" encoding="utf-8"?><container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container"><rootfiles><rootfile full-path="content.opf" media-type="application/oebps-package+xml"/></rootfiles></container>'
		container.close()

		#4. toc.ncx
		toc_header = <<-EOS
<?xml version="1.0" encoding="utf-8"?>
		<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
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
			s + "<navPoint id=\"chapter#{c.seqno}\" class=\"chapter\" playOrder=\"#{c.seqno}\">\n<navLabel>\n<text>#{c.title}</text>\n</navLabel>\n<content src=\"content/chapter#{c.seqno}.html\" />\n</navPoint>\n"
		} + "</navMap>\n"

		toc = File.open(dir + "toc.ncx", "w")
		toc << toc_header
		toc << toc_entries + "</ncx>"
		toc.close()

		#5. finally, the html-files for each chapter
		@chapters.each do |chapter|
			n = chapter.seqno
			f = File.open(dir + "content/chapter#{n}.html", "w")
			f << chapter.text
			f.close()
		end

		puts "Successfully wrote epub file structure to #{dir}."
	end

	def write_to_file(filename)
		name = filename.chomp(".epub") + ".epub"
		dir = "tmp"
		# apparently, the Dir class can only delete empty directorys
		system("rm -r " + dir) if File.exist? dir
		Dir.mkdir(dir)
		write_to_dir(dir)
		puts "Archiving contents of #{dir}"

		# epub standard requires the file 'mimetype' to be the first
		# file in the archive (content starting at byte 38!) and 
		# to be uncompressed
		Zip::ZipOutputStream::open(name) { |os|
			os.put_next_entry("mimetype", Zlib::NO_COMPRESSION)
			os << "application/epub+zip"
		}

		#afterwards, we can begin adding the "normal" files
		zipfile = Zip::ZipFile.open(name)
		Dir.each_recursive(dir) do |path, filename|
			real_path = path + filename
			archive_path = path.sub(dir + "/", "") + filename
			if !File.directory?(real_path) && !(filename == "mimetype")
				zipfile.add(archive_path, real_path)
			end
		end
		zipfile.commit
		system("rm -r " + dir)
		puts "Successfully created file #{name}."
	end
end

class Dir
	def self.each_recursive(path, &block)
		Dir.foreach(path) do |fname|
			if fname == "." || fname == ".."
				#ignore
			else
				block.call(path + "/", fname)

				#recurse if possible
				if File.directory?(path + "/" + fname)
					each_recursive(path+"/"+fname, &block)
				end
			end
		end
	end
end
