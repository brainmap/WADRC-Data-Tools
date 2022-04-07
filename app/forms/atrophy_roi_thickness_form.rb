class AtrophyRoiThicknessForm

	include ActiveModel::Model
	include ActiveModel::Serialization

	attr_accessor :enrollment_id, :enumber, :scan_procedure_id, :scan_procedure_codename, :participant_id, :atlas, :region
	attr_accessor :roi_number, :thickness

	def self.attributes
		{

			'enumber' => nil, 
			'enrollment_id' => nil, 
			'scan_procedure_codename' => nil,
			'scan_procedure_id' => nil,
			'participant_id' => nil,
			'atlas' => '',
			'region' => '',
			'roi_number' => nil,
			'thickness' => nil
		}
	end

	def self.from_csv (csv, subject_id, scan_procedure)
		choices = {}

		#need to match this log file to its petscan, which we can also know from its path

		enr = Enrollment.where(:enumber => subject_id).first
		if !enr.nil?
			choices['participant_id'] = enr.participant_id
			choices['enrollment_id'] = enr.id
			choices['enumber'] = enr.enumber
		end

		sp = ScanProcedure.where(:codename => scan_procedure).first
		if !sp.nil?
			choices['scan_procedure_id'] = sp.id
			choices['scan_procedure_codename'] = sp.codename
		end

		choices['atlas'] = csv['Atlas'].to_s
		choices['region'] = csv['Region'].to_s
		choices['roi_number'] = csv['roi_number'].to_i
		choices['thickness'] = csv['thickness'].to_f

		return self.new(choices)
	end

	def attributes
		{
			'enumber' => @enumber, 
			'enrollment_id' => @enrollment_id, 
			'scan_procedure_codename' => @scan_procedure_codename,
			'scan_procedure_id' => @scan_procedure_id,
			'participant_id' => @participant_id,
			'atlas' => @atlas,
			'region' => @region,
			'roi_number' => @roi_number,
			'thickness' => @thickness
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

# CREATE TABLE `cg_atrophy_roi_thickness_new` (
#   `id` int NOT NULL DEFAULT '0',
#   `subject_id` varchar(255) DEFAULT NULL,
#   `scan_procedure` varchar(255) DEFAULT NULL,
#   `participant_id` int DEFAULT NULL,
#   `atlas` varchar(100) DEFAULT NULL,
#   `region` varchar(100) DEFAULT NULL,
#   `roi_number` int(11) DEFAULT NULL,
#   `thickness` float DEFAULT NULL
# )
