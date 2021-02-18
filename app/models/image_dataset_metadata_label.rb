class ImageDatasetMetadataLabel < ActiveRecord::Base

end

# CREATE TABLE `image_dataset_metadata_labels` (
#   `id` int NOT NULL AUTO_INCREMENT,
#   `address` varchar(9) DEFAULT NULL,
#   `label` varchar(100) DEFAULT NULL,
#   `comment` varchar(1000) DEFAULT NULL,
#   PRIMARY KEY (`id`)
# )