class Processedimage < ApplicationRecord
	has_many :processedimagesources,:class_name =>"Processedimagesource", :dependent => :destroy 
end
