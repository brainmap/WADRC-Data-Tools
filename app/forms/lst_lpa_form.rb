class LstLpaForm

	include ActiveModel::Model
	include ActiveModel::Serialization

	attr_accessor :subject_id, :scan_procedure, :os_version, :matlab_version, :spm_version
	attr_accessor :spm_revision, :lst_version, :lstlpa_local_code_version
	attr_accessor :original_image_path_flair, :original_image_path_T1, :lesion_volume_ml
	attr_accessor :number_of_lesions, :created_at, :processed_at, :participant_id


	def self.attributes
		{
			'subject_id' => nil,
			'scan_procedure' => nil,
			'os_version' => '',
			'matlab_version' => '', 
			'spm_version' => '',
			'spm_revision' => '', 
			'lst_version' => '', 
			'lstlpa_local_code_version' => '', 
			'original_image_path_flair' => '', 
			'original_image_path_T1' => '', 
			'lesion_volume_ml' => 0.0, 
			'number_of_lesions' => 0, 
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

		choices['scan_procedure'] = hash_flip["Protocol"]
		choices['os_version'] = hash_flip['OS version'].to_s
		choices['matlab_version'] = hash_flip["MATLAB version"].to_s
		choices['spm_version'] = hash_flip["SPM version"].to_s
		choices['spm_revision'] = hash_flip["SPM revsion"].to_s
		choices['lst_version'] = hash_flip["LST version"].to_s
		choices['lstlpa_local_code_version'] = hash_flip["lstlpa local code version"].to_s
		choices['original_image_path_flair'] = hash_flip["original_image_path_flair"].to_s
		choices['original_image_path_T1'] = hash_flip["original_image_path_T1"].to_s
		choices['lesion_volume_ml'] = hash_flip['lesion_volume_ml'].to_f
		choices['number_of_lesions'] = hash_flip['number_of_lesions'].to_i
		choices['created_at'] =  DateTime.now()

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
			'lst_version' => @lst_version, 
			'lstlpa_local_code_version' => @lstlpa_local_code_version, 
			'original_image_path_flair' => @original_image_path_flair, 
			'original_image_path_T1' => @original_image_path_T1, 
			'lesion_volume_ml' => @lesion_volume_ml, 
			'number_of_lesions' => @number_of_lesions, 
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
