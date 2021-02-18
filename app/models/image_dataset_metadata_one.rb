class ImageDatasetMetadataOne < ActiveRecord::Base

	self.table_name = 'image_dataset_metadata_001'

	belongs_to :image_dataset

    # alias_attribute :body_part, :_0018_0015
	alias_attribute :scanning_sequence, :_0018_0020
	alias_attribute :sequence_variant, :_0018_0021
	alias_attribute :scan_options, :_0018_0022
	alias_attribute :mr_acquisition_type, :_0018_0023
	alias_attribute :protocol_name, :_0018_1030
	alias_attribute :receive_coil_name, :_0018_1250
end