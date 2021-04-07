class Jobs::ImageReconciliation::ImageReconciliationForm

	include ActiveModel::Model
	include ActiveModel::Serialization

	attr_accessor :image_dataset_id, :enumber, :scan_procedure
	attr_accessor :raw_path_exists, :longest_existing_raw_path, :bz2s_exist_in_raw, :bz2_count
	attr_accessor :bz2_count_matches_image, :preprocessed_path_exists, :longest_existing_preprocessed_path
	attr_accessor :best_matching_candidate, :matched_with_study_id, :matched_count_with_study_id, :matched_count_without_study_id
	attr_accessor :scan_archives


	def self.attributes
		{
			"image_dataset_id" => nil,
			"enumber" => '',
			"scan_procedure" => '',
			"raw_path_exists" => nil,
			"longest_existing_raw_path" => '',
			"bz2s_exist_in_raw" => nil,
			"bz2_count" => 0,
			"bz2_count_matches_image" => nil,
			"preprocessed_path_exists" => nil,
			"longest_existing_preprocessed_path" => '',
			"best_matching_candidate" => '',
			"matched_with_study_id" => nil,
			"matched_count_with_study_id" => nil,
			"matched_count_without_study_id" => nil,
			"scan_archives" => nil
		}
	end

	def self.from_result(result)
		choices = {}

		image = result[:image]
		choices['image_dataset_id'] = image.id


		enrollments = image.visit.appointment.vgroup.enrollments
	    scan_procedures = image.visit.appointment.vgroup.scan_procedures
	    path_relevant_sp = scan_procedures.select{|item| image.path =~ Regexp.new(item.codename)}.first
	    path_relevant_enrollment = enrollments.select{|item| image.path =~ Regexp.new(item.enumber)}.first

		choices["enumber"] = path_relevant_enrollment.enumber
		choices["scan_procedure"] = path_relevant_sp.codename

		choices["raw_path_exists"] = result[:raw_path_exists].to_s
		choices["longest_existing_raw_path"] = result[:longest_existing_raw_path]
		choices["bz2s_exist_in_raw"] = result[:bz2s_exist_in_raw].to_s
		choices["bz2_count"] = result[:bz2_count].to_i
		choices["bz2_count_matches_image"] = result[:bz2_count_matches_image].to_s
		choices["preprocessed_path_exists"] = result[:preprocessed_path_exists].to_s
		choices["longest_existing_preprocessed_path"] = result[:longest_existing_preprocessed_path]
		choices["best_matching_candidate"] = result[:best_matching_candidate]
		choices["matched_with_study_id"] = result[:matched_with_study_id].to_s
		choices["matched_count_with_study_id"] = result[:matched_count_with_study_id].to_i
		choices["matched_count_without_study_id"] = result[:matched_count_without_study_id].to_i
		choices["scan_archives"] = result[:scan_archives].to_s

		return self.new(choices)
	end

	def attributes
		{
			"image_dataset_id" => @image_dataset_id,
			"enumber" => @enumber,
			"scan_procedure" => @scan_procedure,
			"raw_path_exists" => @raw_path_exists,
			"longest_existing_raw_path" => @longest_existing_raw_path,
			"bz2s_exist_in_raw" => @bz2s_exist_in_raw,
			"bz2_count" => @bz2_count,
			"bz2_count_matches_image" => @bz2_count_matches_image,
			"preprocessed_path_exists" => @preprocessed_path_exists,
			"longest_existing_preprocessed_path" => @longest_existing_preprocessed_path,
			"best_matching_candidate" => @best_matching_candidate,
			"matched_with_study_id" => @matched_with_study_id,
			"matched_count_with_study_id" => @matched_count_with_study_id,
			"matched_count_without_study_id" => @matched_count_without_study_id,
			"scan_archives" => @scan_archives
		}
	end

	def to_sql_insert(table_name='image_dataset_reconciliation')
		columns = []
		values = []
		connection = ActiveRecord::Base.connection
		attributes.keys.each do |key|
			columns << key
			values << (attributes[key].nil? ? "NULL" : connection.quote(attributes[key]))
		end

		return "INSERT INTO #{table_name} (#{columns.join(', ')}) values (#{values.join(', ')});"
	end

end


# CREATE TABLE `image_dataset_reconciliation` (
# `id` int NOT NULL AUTO_INCREMENT,
# `image_dataset_id` int(11) DEFAULT NULL,
# `enumber` varchar(24) DEFAULT NULL,
# `scan_procedure` varchar(100) DEFAULT NULL,
# `raw_path_exists` varchar(5) DEFAULT NULL,
# `longest_existing_raw_path` varchar(255) DEFAULT NULL,
# `bz2s_exist_in_raw` varchar(5) DEFAULT NULL,
# `bz2_count` int DEFAULT NULL,
# `bz2_count_matches_image` varchar(5) DEFAULT NULL,
# `preprocessed_path_exists` varchar(5) DEFAULT NULL,
# `longest_existing_preprocessed_path` varchar(255) DEFAULT NULL,
# `best_matching_candidate` varchar(255) DEFAULT NULL,
# `matched_with_study_id` varchar(5) DEFAULT NULL,
# `matched_count_with_study_id` int DEFAULT NULL,
# `matched_count_without_study_id` int DEFAULT NULL,
# `scan_archives` varchar(5) DEFAULT NULL,
# `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
# PRIMARY KEY (`id`)
# );


