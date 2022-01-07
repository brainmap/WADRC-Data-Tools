class AtrophyRoiForm

	include ActiveModel::Model
	include ActiveModel::Serialization

	attr_accessor :subject_id, :scan_procedure, :participant_id, :atlas, :region
	attr_accessor :roi_number, :v_gm, :v_wm, :v_csf

	def self.attributes
		{

			'subject_id' => nil, 
			'scan_procedure' => nil,
			'participant_id' => nil,
			'atlas' => '',
			'region' => '',
			'roi_number' => nil,
			'v_gm' => nil,
			'v_wm' => nil,
			'v_csf' => nil
		}
	end

	def self.from_csv (csv, subject_id, scan_procedure)
		choices = {}

		#need to match this log file to its petscan, which we can also know from its path

		choices['subject_id'] = subject_id

		enr = Enrollment.where(:enumber => choices['subject_id']).first
		if !enr.nil?
			choices['participant_id'] = enr.participant_id
		end

		choices['scan_procedure'] = scan_procedure
		choices['atlas'] = csv['Atlas'].to_s
		choices['region'] = csv['Region'].to_s
		choices['roi_number'] = csv['roi_number'].to_i
		choices['v_gm'] = csv['Vgm'].to_f
		choices['v_wm'] = csv['Vwm'].to_f
		choices['v_csf'] = csv['Vcsf'].to_f

		return self.new(choices)
	end

	def attributes
		{
			'subject_id' => @subject_id, 
			'scan_procedure' => @scan_procedure, 
			'participant_id' => @participant_id,
			'atlas' => @atlas,
			'region' => @region,
			'roi_number' => @roi_number,
			'v_gm' => @v_gm,
			'v_wm' => @v_wm,
			'v_csf' => @v_csf
		}
	end

	def to_sql_insert(table_name='')
		columns = []
		values = []
		connection = ActiveRecord::Base.connection
		attributes.keys.each do |key|
			# puts "#{key} #{attributes[key]}"
			columns << key
			values << (attributes[key].nil? ? "NULL" : connection.quote(attributes[key]))
		end

		return "INSERT INTO #{table_name} (#{columns.join(', ')}) values (#{values.join(', ')});"
	end

end

# CREATE TABLE `cg_atrophy_roi_new` (
#   `id` int NOT NULL DEFAULT '0',
#   `subject_id` varchar(255) DEFAULT NULL,
#   `scan_procedure` varchar(255) DEFAULT NULL,
#   `participant_id` int DEFAULT NULL,
#   `atlas` varchar(100) DEFAULT NULL,
#   `region` varchar(100) DEFAULT NULL,
#   `roi_number` int(11) DEFAULT NULL,
#   `v_gm` float DEFAULT NULL,
#   `v_wm` float DEFAULT NULL,
#   `v_csf` float DEFAULT NULL
# )
