class ImageComment < ActiveRecord::Base
  belongs_to :image_dataset
  belongs_to :user

  validates_presence_of :user
  validates_presence_of :image_dataset
end
