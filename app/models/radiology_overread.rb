class RadiologyOverread < ActiveRecord::Base

	# These hold information from the JSON export from the radiology site. See also Jobs::RemoteRequest::RadiologyRequest
	# for more info on how we pull and record these.

	belongs_to :visit

	def from_form(form)

		self.scan_entry_date = form.scan_entry_date

		self.dob = form.dob

		self.gender = form.gender
		self.white_matter_change = form.white_matter_change
		self.adrc_large_vessel_infarcts = form.adrc_large_vessel_infarcts
		self.adrc_lacunar_infarcts = form.adrc_lacunar_infarcts
		self.adrc_macrohemorrhages = form.adrc_macrohemorrhages
		self.adrc_microhemorrhages = form.adrc_microhemorrhages
		self.adrc_moderate_white_matter_hyperintensity = form.adrc_moderate_white_matter_hyperintensity
		self.adrc_extensive_white_matter_hyperintensity = form.adrc_extensive_white_matter_hyperintensity
		self.summary = form.summary
		self.comments = form.comments

		self.clerical_notes = form.clerical_notes
		self.reader_last_name = form.reader_last_name
		self.reader_first_name = form.reader_first_name
		self.read_date = form.read_date
		self.mpnrage_uncorrected = form.mpnrage_uncorrected
		self.mpnrage_classic_moco = form.mpnrage_classic_moco
		self.mpnrage_new_recon = form.mpnrage_new_recon
		self.white_matter_score = form.white_matter_score

		return self
	end

end

# CREATE TABLE `radiology_overreads` (
#   `id` int NOT NULL AUTO_INCREMENT,
#   `visit_id` int DEFAULT NULL,
#   `scan_entry_date` date DEFAULT NULL,
#   `rmr` varchar(20) DEFAULT NULL,
#   `gender` varchar(2) DEFAULT NULL,
#   `dob` date DEFAULT NULL,
#   `white_matter_change` varchar(2) DEFAULT NULL,
#   `adrc_large_vessel_infarcts` varchar(2) DEFAULT NULL,
#   `adrc_lacunar_infarcts` varchar(2) DEFAULT NULL,
#   `adrc_macrohemorrhages` varchar(2) DEFAULT NULL,
#   `adrc_moderate_white_matter_hyperintensity` varchar(2) DEFAULT NULL,
#   `adrc_extensive_white_matter_hyperintensity` varchar(2) DEFAULT NULL,
#   `summary` varchar(2000) DEFAULT NULL,
#   `comments` varchar(2000) DEFAULT NULL,
#   `adrc_microhemorrhages` varchar(2) DEFAULT NULL,
#   `clerical_notes` varchar(2000) DEFAULT NULL,
#   `reader_last_name` varchar(40) DEFAULT NULL,
#   `reader_first_name` varchar(40) DEFAULT NULL,
#   `read_date` date DEFAULT NULL,
#   `mpnrage_uncorrected` varchar(2) DEFAULT NULL,
#   `mpnrage_classic_moco` varchar(2) DEFAULT NULL,
#   `mpnrage_new_recon` varchar(2) DEFAULT NULL,
#   PRIMARY KEY (`id`)
# )