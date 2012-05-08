class LookupPettracer < ActiveRecord::Base
  
  def name_description
    "#{self.name}  - #{self.description} "
  end
end
