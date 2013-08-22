class Measurement < ActiveRecord::Base
	# measurements are in KB!
	# Calculated using du -s -k <directory>
	belongs_to :directory
	
	validates_numericality_of :size
	validates_presence_of :size
	
	def mb_size
		size.to_f / 2**10
	end
	
	def gb_size
		size.to_f / 2**20
	end
	
	def size_string
		return '' unless size
		(size > 2**20) ? ("%0.2f GB" % gb_size) : ("%0.2f MB" % mb_size)
	end
	
end