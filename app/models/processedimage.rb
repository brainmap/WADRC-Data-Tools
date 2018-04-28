class Processedimage <  ActiveRecord::Base
	has_many :processedimagessources,:class_name =>"Processedimagessource", :dependent => :destroy 
end
