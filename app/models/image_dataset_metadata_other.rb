class ImageDatasetMetadataOther < ActiveRecord::Base

	self.table_name = 'image_dataset_metadata_other'
	belongs_to :image_dataset

	alias_attribute :mri_station_name, :_0008_1010
	alias_attribute :study_description, :_0008_1030
	alias_attribute :series_description, :_0008_103E
end