class CentiloidForm

	include ActiveModel::Model
	include ActiveModel::Serialization

	attr_accessor :petscan_id, :subject_id, :centiloid_value, :reference_roi, :signal_roi
	attr_accessor :pet_method, :signal_value, :reference_value, :renormalized_value, :age_at_appointment
	attr_accessor :source_file_path, :input_file_path, :image_path, :code_version, :created_at, :processed_at
	attr_accessor :participant_id, :comment, :cerebellar_gm_value, :whole_cerebellum_value, :pons_value

	def self.attributes
		{
			'petscan_id' => nil,
			'subject_id' => '',
			'centiloid_value' => 0.0,
			'reference_roi' => '',
			'signal_roi' => '',
			'pet_method' => '',
			'signal_value' => 0.0,
			'reference_value' => 0.0,
			'renormalized_value' => 0.0,
			'age_at_appointment' => '',
			'source_file_path' => '',
			'input_file_path' => '',
			'image_path' => '',
			'code_version' => '',
			'created_at' => '',
			'processed_at' => '',
			'participant_id' => '',
			'comment' => '',
			'cerebellar_gm_value' => '',
			'whole_cerebellum_value' => '',
			'pons_value' => ''
		}
	end

	def self.from_csv (csv, pet_method, source_file_path, petscan)
		#here, we're taking a whole CSV and digesting it, rather than just one row per new object

		values = {}
		csv.each do |row|
			values[row["Description"]] = row["Value"]
		end

		choices = {}

		#need to match this log file to its petscan, which we can also know from its path

		choices['petscan_id'] = petscan.id
		choices['subject_id'] = values["subject/study ID"].to_s

		enr = Enrollment.where(:enumber => choices['subject_id']).first
		if !enr.nil?
			choices['participant_id'] = enr.participant_id
		end
		
		choices['centiloid_value'] = values["Centiloid"].to_f
		choices['reference_roi'] = "Whole Cerebellum"
		choices['signal_roi'] = "Cortex"
		choices['pet_method'] = pet_method.downcase
		choices['signal_value'] = values["#{pet_method.upcase} for signal VOI"].to_f
		choices['reference_value'] = values["#{pet_method.upcase} for reference VOI"].to_f
		choices['renormalized_value'] = values["renormalized #{pet_method.upcase}"].to_f
		choices['cerebellar_gm_value'] = values["#{pet_method.upcase} with reference CerebellarGM"].to_f
		choices['whole_cerebellum_value'] = values["#{pet_method.upcase} with reference WholeCerebellum plus Brain Stem"].to_f
		choices['pons_value'] = values["#{pet_method.upcase} with reference Pons"].to_f

		appt = petscan.appointment
		if !appt.nil?
			choices['age_at_appointment'] = appt.age_at_appointment.to_f
		end

		choices['source_file_path'] = source_file_path
		choices['input_file_path'] = values["Input file"].to_s
		choices['image_path'] = values["image_path"].to_s
		
		choices['code_version'] = values["Version"].to_s
		choices['comment'] = values["VOI Comment"]
		choices['created_at'] = DateTime.now()

		choices['processed_at'] = ''
		if !values["processed_at"].nil? and !values["processed_at"].blank?
			choices['processed_at'] = DateTime.strptime(values["processed_at"],"%Y-%m-%d %H:%M:%S")
		end

		return self.new(choices)
	end

	def attributes
		{
			'petscan_id' => @petscan_id,
			'subject_id' => @subject_id,
			'centiloid_value' => @centiloid_value,
			'reference_roi' => @reference_roi,
			'signal_roi' => @signal_roi,
			'pet_method' => @pet_method,
			'signal_value' => @signal_value,
			'reference_value' => @reference_value,
			'renormalized_value' => @renormalized_value,
			'age_at_appointment' => @age_at_appointment,
			'source_file_path' => @source_file_path,
			'input_file_path' => @input_file_path,
			'image_path' => @image_path,
			'code_version' => @code_version,
			'created_at' => @created_at,
			'processed_at' => @processed_at,
			'participant_id' => @participant_id,
			'comment' => @comment,
			'cerebellar_gm_value' => @cerebellar_gm_value,
			'whole_cerebellum_value' => @whole_cerebellum_value,
			'pons_value' => @pons_value
		}
	end

	def to_sql_insert(table_name='')
		columns = []
		values = []
		connection = ActiveRecord::Base.connection
		attributes.keys.each do |key|
			if key == 'pet_method'
				columns << 'method'
			else
				columns << key
			end
			values << (attributes[key].nil? ? "NULL" : connection.quote(attributes[key]))
		end

		return "INSERT INTO #{table_name} (#{columns.join(', ')}) values (#{values.join(', ')});"
	end

end
