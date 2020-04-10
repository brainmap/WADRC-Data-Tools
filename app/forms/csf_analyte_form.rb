class CsfAnalyteForm

	include ActiveModel::Model
	include ActiveModel::Serialization

	attr_accessor :enumber, :wrapnum, :reggieid, :processed_at, :ab_42_value, :ab_42_unit
	attr_accessor :ttau_value, :ttau_unit, :ptau_value, :ptau_unit, :machine
	attr_accessor :tube_type, :sample_type, :frozen_or_fresh, :preanalytic_protocol, :sample_visit_date, :notes

	validate :validate_enumber

	def self.attributes
		{
			'enumber' => '',
			'wrapnum' => '',
			'reggieid' => '',
			'processed_at' => '',
			'ab_42_value' => 0.0,
			'ab_42_unit' => '',
			'ttau_value' => 0.0,
			'ttau_unit' => '',
			'ptau_value' => 0.0,
			'ptau_unit' => '',
			'machine' => '',
			'tube_type' => '',
			'sample_type' => '',
			'frozen_or_fresh' => '',
			'preanalytic_protocol' => '',
			'sample_visit_date' => '',
			'notes' => ''
		}
	end

	def self.from_csv (row)
		choices = {}

		#we do this one first, so that we can use it for weird values a few lines down
		choices['notes'] = row["Notes"].to_s

		#we need to clean these and get them looking more like the Panda's enumbers
		choices['enumber'] = row[0].to_s.lstrip.downcase.gsub(/[abcdefghijklmnopqrstuvwxyz]$/,'').gsub(/\s/,'')

		choices['wrapnum'] = row["WRAP ID"].to_s
		
		#if reggie id is blank, we need to guess at one. Try to find an Enrollment with the enumber,
		# then use that to find a participant and get the reggie id from there.
		choices['reggieid'] = row["Reggie ID"].to_s
		if choices['reggieid'].blank?
			enrollment = Enrollment.where(:enumber => choices['enumber']).first
			if !enrollment.nil?
				participant = enrollment.participant
				if !participant.nil?
					choices['reggieid'] = participant.reggieid
				end
			end
		end

		choices['processed_at'] = DateTime.strptime(row["Run Date and Time"].to_s)
		choices['ab_42_value'] = row["AB 42 Value"].to_f
		choices['ab_42_unit'] = row[6].to_s.rstrip
		choices['ttau_value'] = row["tTau Value"].to_f
		choices['ttau_unit'] = row[9].to_s.rstrip
		choices['ptau_value'] = row["pTau Value"].to_f
		choices['ptau_unit'] = row[12].to_s.rstrip
		choices['machine'] = row["Machine"].to_s

		# inputs could include: "1.5ml Flip Top", "2.5 Ml Sarstedt", "2 Ml cryovial", "0.5 mL Sarstedt", "2.5ml sarstedt tube", "0.5 Sarstedt tube"
		case row["Tube Type"]
		when "1.5ml Flip Top"
			choices['tube_type'] = LookupRef.where(:label => 'tubetypes', :description => "1.5ml flip top").first.ref_value
		when "2.5 Ml Sarstedt"
			choices['tube_type'] = LookupRef.where(:label => 'tubetypes', :description => "Sarstedt 2.5 mL non-stick").first.ref_value
		when "2 Ml cryovial"
			choices['tube_type'] = LookupRef.where(:label => 'tubetypes', :description => "2 ml cryovial").first.ref_value
		when "0.5 mL Sarstedt"
			choices['tube_type'] = LookupRef.where(:label => 'tubetypes', :description => "Sarstedt 0.5 mL screw top").first.ref_value
		when "2.5ml sarstedt tube"
			choices['tube_type'] = LookupRef.where(:label => 'tubetypes', :description => "Sarstedt 2.5 mL non-stick").first.ref_value
		when "0.5 Sarstedt tube"
			choices['tube_type'] = LookupRef.where(:label => 'tubetypes', :description => "Sarstedt 0.5 mL screw top").first.ref_value
		else
			choices['tube_type'] = nil
			choices['notes'] += "\n'Tube Type' was '#{row["Tube Type"].to_s}'"
		end

		# row["Sample Type"].downcase should always be 'csf'
		choices['sample_type'] = row["Sample Type"].to_s.downcase
		
		# row["Frozen or Fresh"].downcase should either be "fresh" or "frozen", but sometimes
		# there's more in the column. In those cases we should at least be able to check if
		# the value contains "fresh" or "frozen", map accordingly, and add the raw value to 
		# the notes
		if row["Frozen or Fresh"].to_s.downcase == 'fresh'
			choices['frozen_or_fresh'] = 'fresh'
		elsif row["Frozen or Fresh"].to_s.downcase == 'frozen'
			choices['frozen_or_fresh'] = 'frozen'
		elsif row["Frozen or Fresh"].to_s.downcase == 'frozen 2/20'
			choices['frozen_or_fresh'] = 'frozen late'
		elsif row["Frozen or Fresh"].to_s.downcase.include? 'fresh'
			choices['frozen_or_fresh'] = 'fresh'
			choices['notes'] += "\n'Frozen or Fresh' was '#{row["Frozen or Fresh"].to_s}'"
		elsif row["Frozen or Fresh"].to_s.downcase.include? 'frozen'
			choices['frozen_or_fresh'] = 'frozen'
			choices['notes'] += "\n'Frozen or Fresh' was '#{row["Frozen or Fresh"].to_s}'"
		else
			#wtf?
			choices['frozen_or_fresh'] = ''
			choices['notes'] += "\n'Frozen or Fresh' was '#{row["Frozen or Fresh"].to_s}'"
		end

		# row["Preanalytic Protocol"].downcase should be in ["pull", "fresh", "drip"]
		choices['preanalytic_protocol'] = row["Preanalytic Protocol"].to_s.downcase

		choices['sample_visit_date'] = row["Sample Visit Date"].blank? ? nil : Date.strptime(row["Sample Visit Date"].to_s)

		return self.new(choices)
	end

	def attributes
		{
			'enumber' => @enumber,
			'wrapnum' => @wrapnum,
			'reggieid' => @reggieid,
			'processed_at' => @processed_at,
			'ab_42_value' => @ab_42_value,
			'ab_42_unit' => @ab_42_unit,
			'ttau_value' => @ttau_value,
			'ttau_unit' => @ttau_unit,
			'ptau_value' => @ptau_value,
			'ptau_unit' => @ptau_unit,
			'machine' => @machine,
			'tube_type' => @tube_type,
			'sample_type' => @sample_type,
			'frozen_or_fresh' => @frozen_or_fresh,
			'preanalytic_protocol' => @preanalytic_protocol,
			'sample_visit_date' => @sample_visit_date,
			'notes' => @notes
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

	def validate_enumber
		# this is supposed to tell us if the first column on the input spreadsheet matches an enumber in the Panda
		if Enrollment.where(:enumber => @enumber).count == 0
			errors.add(:enumber, "should match an existing enrollment enumber")
		end
	end

end
