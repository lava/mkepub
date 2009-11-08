require 'common/chapter'

class Book
	attr_accessor :title, :author, :year, :lang
	attr_reader :chapters

	def initialize(book_info = {})
		@title = book_info.fetch(:title, "")
		@author = book_info.fetch(:author, "")
		@year = book_info.fetch(:year, "")
		@lang = book_info.fetch(:lang, "")
		@chapters = []
	end

	def add_chapter(seqno, title, text)
		@chapters << Chapter.new(seqno, title, text)
	end
end
