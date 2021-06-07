class TrTag < ActiveRecord::Base
	has_and_belongs_to_many :trfiles 

end


# CREATE TABLE `tr_tags` (
#   `id` int NOT NULL AUTO_INCREMENT,
#   `name` varchar(100) DEFAULT NULL,
#   PRIMARY KEY (`id`)
# );
# CREATE TABLE `trfiles_tr_tags` (
#   `id` int NOT NULL AUTO_INCREMENT,
#   `trfile_id` int(11) NOT NULL,
#   `tr_tag_id` int(11) NOT NULL,
#   PRIMARY KEY (`id`)
# );