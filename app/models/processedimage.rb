class Processedimage < ApplicationRecord
	has_many :processedimagesources,:class_name =>"Processedimagessource", :dependent => :destroy 
end
