class ImageDatasetQualityCheck < ActiveRecord::Base
  belongs_to :user
  belongs_to :image_dataset

end
