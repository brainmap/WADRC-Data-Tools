class ImageDatasetMetadataTwo < ActiveRecord::Base

	self.table_name = 'image_dataset_metadata_002'
	belongs_to :image_dataset
end
