class ImageDatasetMetadataFour < ActiveRecord::Base

	self.table_name = 'image_dataset_metadata_004'
	belongs_to :image_dataset

	alias_attribute :filter_mode, :_0043_102D
	scope :pure_corrected, -> { where(:_0043_102D => ["P+","p+","wp+"])}
end