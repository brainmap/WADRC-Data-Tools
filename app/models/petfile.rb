class Petfile < ActiveRecord::Base
  attr_accessible :file_name, :id, :note, :path, :petscan_id
  belongs_to :petscan
end
