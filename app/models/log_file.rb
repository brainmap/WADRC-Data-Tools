class LogFile < ActiveRecord::Base
  has_many :log_file_entries
  
  belongs_to :visit
  belongs_to :image_dataset
end
