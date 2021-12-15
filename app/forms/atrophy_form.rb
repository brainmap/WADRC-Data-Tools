class AtrophyForm

	include ActiveModel::Model
	include ActiveModel::Serialization

	attr_accessor :subject_id, :scan_procedure, :os_version, :matlab_version, :spm_version
	attr_accessor :spm_revision, :cat12_release, :cat12_version, :cat12_date, :atrophy_local_code_version
	attr_accessor :original_image_path, :tiv, :gm_volume, :wm_volume, :csf_volume, :wmh_volume
	attr_accessor :iqr_percent, :iqr_letter_grade, :created_at, :processed_at, :participant_id

	def self.attributes
		{

			'subject_id' => nil, 
			'scan_procedure' => nil, 
			'os_version' => '', 
			'matlab_version' => '', 
			'spm_version' => '', 
			'spm_revision' => '', 
			'cat12_release' => '', 
			'cat12_version' => '', 
			'cat12_date' => '', 
			'atrophy_local_code_version' => '', 
			'original_image_path' => '', 
			'tiv' => 0.0,
			'gm_volume' => 0.0,
			'wm_volume' => 0.0,
			'csf_volume' => 0.0,
			'wmh_volume' => 0.0,
			'iqr_percent' => 0.0,
			'iqr_letter_grade' => '', 
			'created_at' => '', 
			'processed_at' => '', 
			'participant_id' => nil
		}
	end

	def self.from_csv (csv)
		#here, we're taking a whole CSV and digesting it, rather than just one row per new object


		values = {}
		comments = {}

		hash_flip = csv.each_with_object(Hash.new()){|item,hash| hash[item["Description"]] = item["Value"]}

		choices = {}

		#need to match this log file to its petscan, which we can also know from its path

		choices['subject_id'] = hash_flip["Enumber"].to_s

		enr = Enrollment.where(:enumber => choices['subject_id']).first
		if !enr.nil?
			choices['participant_id'] = enr.participant_id
		end

		choices['scan_procedure'] = hash_flip["scan procedure"].to_s
		choices['os_version'] = hash_flip["OS version"].to_s
		choices['matlab_version'] = hash_flip["MATLAB version"].to_s
		choices['spm_version'] = hash_flip["SPM version"].to_s
		choices['spm_revision'] = hash_flip["SPM revision"].to_s
		choices['cat12_release'] = hash_flip["CAT12 release"].to_s
		choices['cat12_version'] = hash_flip["CAT12 version"].to_s
		choices['cat12_date'] = hash_flip["CAT12 date"].to_s
		choices['atrophy_local_code_version'] = hash_flip["atrophy local code version"].to_s
		choices['original_image_path'] = hash_flip["original_image_path"].to_s
		choices['tiv'] = hash_flip["TIV"].to_f
		choices['gm_volume'] = hash_flip["GM volume"].to_f
		choices['wm_volume'] = hash_flip["WM volume"].to_f
		choices['csf_volume'] = hash_flip["CSF volume"].to_f
		choices['wmh_volume'] = hash_flip["WMH volume"].to_f
		choices['iqr_percent'] = hash_flip["%IQR"].to_f
		choices['iqr_letter_grade'] = hash_flip["IQR Letter Grade"]
		choices['created_at'] = DateTime.now()

		choices['processed_at'] = ''
		if !hash_flip["processed_at"].nil? and !hash_flip["processed_at"].blank?
			choices['processed_at'] = DateTime.strptime(hash_flip["processed_at"],"%Y-%m-%d %H:%M:%S")
		end

		return self.new(choices)
	end

	def attributes
		{
			'subject_id' => @subject_id, 
			'scan_procedure' => @scan_procedure, 
			'os_version' => @os_version, 
			'matlab_version' => @matlab_version, 
			'spm_version' => @spm_version, 
			'spm_revision' => @spm_revision, 
			'cat12_release' => @cat12_release, 
			'cat12_version' => @cat12_version, 
			'cat12_date' => @cat12_date, 
			'atrophy_local_code_version' => @atrophy_local_code_version, 
			'original_image_path' => @original_image_path, 
			'tiv' => @tiv,
			'gm_volume' => @gm_volume,
			'wm_volume' => @wm_volume,
			'csf_volume' => @csf_volume,
			'wmh_volume' => @wmh_volume,
			'iqr_percent' => @iqr_percent,
			'iqr_letter_grade' => @iqr_letter_grade, 
			'created_at' => @created_at, 
			'processed_at' => @processed_at, 
			'participant_id' => @participant_id
		}
	end

	def to_sql_insert(table_name='')
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
