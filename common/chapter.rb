class Chapter
	attr_accessor :title, :text, :seqno

	def initialize(seqno = 0, title = "", text = "")
		@seqno = seqno
		@title = title
		@text = text
	end
end
