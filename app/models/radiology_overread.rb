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

		return self
	end

end

# id 
# scanEntryDate
# subjID
# gender
# DOB
# whiteMatterChange
# ADRC_large_vessel_infarcts
# ADRC_lacunar_infarcts
# ADRC_macrohemorrhages
# ADRC_microHemorrhages
# ADRC_moderate_white_matter_hyperintensity
# ADRC_extensive_white_matter_hyperintensity
# summary
# comments


# CREATE TABLE `radiology_overreads` (
#   `id` int(11) NOT NULL AUTO_INCREMENT,
#   `visit_id` int(11) DEFAULT NULL,
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
#   PRIMARY KEY (`id`)
# )