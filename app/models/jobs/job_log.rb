class Jobs::JobLog

	# this is a little helper class for logging within jobs.
	# All it does is timestamp entries as they come in, and serialize for writing out to a file, or attaching with 
	# Active Storage.
	attr_accessor :content

	def initialize
		self.content = []
	end

	def << (value)
		self.content << "[#{DateTime.now().strftime("%Y-%m-%d %H:%M:%S.%L")}] #{value.to_s}"
	end

	def serialize

		out = self.content.join("\n")

		return out
	end


end