class Processedimage < ApplicationRecord
	has_many :processedimagessources,:class_name =>"Processedimagessource", :dependent => :destroy 
end
