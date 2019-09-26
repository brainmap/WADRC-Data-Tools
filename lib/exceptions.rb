module Exceptions

	#Petscan
	
	class PetscanError < StandardError; end
	class PetscanPathError < PetscanError; end
	class PetscanTooManyEcatsError < PetscanError; end
	class PetscanNoEcatsError < PetscanError; end
	class PetscanTooManyEcatsError < PetscanError; end

end
