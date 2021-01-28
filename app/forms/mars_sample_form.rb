class MarsSampleForm

	# 2021-01-13 wbbevis -- This is for importing MARS samples 💩

	include ActiveModel::Model
	include ActiveModel::Serialization

	attr_accessor :subjectid, :general_comment, :done_flag, :status_flag, :status_comment
	attr_accessor :enrollment_id, :scan_procedure_id, :sample_id, :sample_date, :sample_time, :storage_date_noon
	attr_accessor :stored_by, :sample_condition, :weight_container_contents_g, :bristol_type, :sample_color
	attr_accessor :storage_location, :forms_present_received, :date_forms_adrc, :forms_received_by, :notes_comments
	attr_accessor :changes_in_sample_disposition_disposal, :displosed_by, :age_at_appt

	attr_accessor :seq_run_1, :seq_run_2, :seq_run_3

	attr_accessor :tube1_tare, :tube1_with_sample, :tube2_tare, :tube2_with_sample, :tube3_tare, :tube3_with_sample
	attr_accessor :dry_tube_tare, :dry_tube_with_sample, :dry_tube_dry_sample_a, :dry_tube_dry_sample_b, :dry_tube_dry_sample_c
	attr_accessor :sample_dry_matter, :qual_ap, :tubes_with_left_column_ids, :transit_days

	def self.attributes
		{
			'subjectid' => '',
			'general_comment' => '',
			'done_flag' => '',
			'status_flag' => '',
			'status_comment' => '',
			'enrollment_id' => '',
			'scan_procedure_id' => '',
			'sample_id' => '',
			'seq_run_1' => '',
			'seq_run_2' => '',
			'seq_run_3' => '',
			'sample_date' => '',
			'sample_time' => '',
			'storage_date_noon' => '',
			'stored_by' => '',
			'sample_condition' => '',
			'weight_container_contents_g' => '',
			'bristol_type' => '',
			'sample_color' => '',
			'tube1_tare' => '',
			'tube1_with_sample' => '',
			'tube2_tare' => '',
			'tube2_with_sample' => '',
			'tube3_tare' => '',
			'tube3_with_sample' => '',
			'dry_tube_tare' => '',
			'dry_tube_with_sample' => '',
			'dry_tube_dry_sample_a' => '',
			'dry_tube_dry_sample_b' => '',
			'dry_tube_dry_sample_c' => '',
			'sample_dry_matter' => '',
			'qual_ap' => '',
			'storage_location' => '',
			'forms_present_received' => '',
			'date_forms_adrc' => '',
			'forms_received_by' => '',
			'notes_comments' => '',
			'changes_in_sample_disposition_disposal' => '',
			'displosed_by' => '',
			'tubes_with_left_column_ids' => '',
			'transit_days' => '',
			'age_at_appt' => ''
		}
	end

	def self.from_csv (row)
		choices = {}

		choices['general_comment'] = row["Notes & Comments"]
		choices['sample_id'] = row["Sample ID #"]

		choices['seq_run_1'] = row["Sequence Run 1"]
		choices['seq_run_2'] = row["Sequence Run 2"]
		choices['seq_run_3'] = row["Sequence Run 3"]

		choices['sample_date'] = row["Sample Date"]
		choices['sample_time'] = row["Sample Time"]
		choices['storage_date_noon'] = row["Storage Date (~noon)"]
		choices['stored_by'] = row["By"]
		choices['sample_condition'] = row["Sample Condition (RT, Cool, Frozen)"]
		choices['weight_container_contents_g'] = row["Weight (Container + Contents) (g) [Container = 54.5g]"]
		choices['bristol_type'] = row["Bristol Type  (1 - 7)"]
		choices['sample_color'] = row["Sample Color"]

		choices['tube1_tare'] = row["BB Sample Tube1 Tare (mg)"]
		choices['tube1_with_sample'] = row["BB Sample Tube1 + Sample (mg)"]
		choices['tube2_tare'] = row["BB Sample Tube2 Tare (mg)"]
		choices['tube2_with_sample'] = row["BB Sample Tube2 + Sample (mg)"]
		choices['tube3_tare'] = row["BB Sample Tube3 Tare (mg)"]
		choices['tube3_with_sample'] = row["BB Sample Tube3 + Sample (mg)"]
		choices['dry_tube_tare'] = row["Dry Wt. Tube Tare (mg)"]
		choices['dry_tube_with_sample'] = row["Dry Wt.Tube + Sample (mg)"]
		choices['dry_tube_dry_sample_a'] = row["Dry Wt. Tube + Sample Dried A (mg)"]
		choices['dry_tube_dry_sample_b'] = row["Dry Wt. Tube + Sample Dried B (mg)"]
		choices['dry_tube_dry_sample_c'] = row["Dry Wt. Tube + Sample Dried C (mg)"]
		choices['sample_dry_matter'] = row["Sample Dry Matter (fraction)"]
		choices['qual_ap'] = row["Qualitative AP"]

		choices['storage_location'] = row["Storage Location"]
		choices['forms_present_received'] = row["Forms Present / Received"]
		choices['date_forms_adrc'] = row["Date Forms  ---> ADRC"]
		choices['forms_received_by'] = row["Forms Received By"]
		choices['notes_comments'] = row["Notes & Comments"]
		choices['changes_in_sample_disposition_disposal'] = row["Changes in Sample Disposition / Disposal"]
		choices['displosed_by'] = row[31] # this was labeled "By", which collides with the "stored_by" column.

		choices['tubes_with_left_column_ids'] = row["12/2020:  BB tubes accidentally recorded with left-column IDs"]
		choices['transit_days'] = row["Transit days"]

		# According to Bob Kerby, the ids here are linked like MARS0001 => 2001 in the spreadsheet.
		# so we should maybe check an enrollment when we pull this up.


		mars_subjectid = "mars00" + row["Sample ID #"][1..-1]
		enr = Enrollment.where(:enumber => mars_subjectid).first
		sp = ScanProcedure.where(:codename => 'bendlin.mars.visit2').first

		if !sp.nil?
			choices['scan_procedure_id'] = sp.id
		end

		if !enr.nil?
			choices['subjectid'] = enr.enumber
			choices['enrollment_id'] = enr.id

			sample_date = Date.strptime(row["Sample Date"], "%Y-%m-%d")

			choices['age_at_appt'] = ((sample_date - enr.participant.dob) / 365.25).ceil(2)
		end
		

		# These fields are on the table, but they're all NULL, and don't have a clear
		# analog on the new spreadsheets, so I'm going to ignore them.

		# 'done_flag'
		# 'status_flag'
		# 'status_comment'

		return self.new(choices)
	end

	def attributes
			
		{
			'subjectid' => @subjectid,
			'general_comment' => @general_comment,
			'done_flag' => @done_flag,
			'status_flag' => @status_flag,
			'status_comment' => @status_comment,
			'enrollment_id' => @enrollment_id,
			'scan_procedure_id' => @scan_procedure_id,
			'sample_id' => @sample_id,
			'seq_run_1' => @seq_run_1,
			'seq_run_2' => @seq_run_2,
			'seq_run_3' => @seq_run_3,
			'sample_date' => @sample_date,
			'sample_time' => @sample_time,
			'storage_date_noon' => @storage_date_noon,
			'stored_by' => @stored_by,
			'sample_condition' => @sample_condition,
			'weight_container_contents_g' => @weight_container_contents_g,
			'bristol_type' => @bristol_type,
			'sample_color' => @sample_color,
			'tube1_tare' => @tube1_tare,
			'tube1_with_sample' => @tube1_with_sample,
			'tube2_tare' => @tube2_tare,
			'tube2_with_sample' => @tube2_with_sample,
			'tube3_tare' => @tube3_tare,
			'tube3_with_sample' => @tube3_with_sample,
			'dry_tube_tare' => @dry_tube_tare,
			'dry_tube_with_sample' => @dry_tube_with_sample,
			'dry_tube_dry_sample_a' => @dry_tube_dry_sample_a,
			'dry_tube_dry_sample_b' => @dry_tube_dry_sample_b,
			'dry_tube_dry_sample_c' => @dry_tube_dry_sample_c,
			'sample_dry_matter' => @sample_dry_matter,
			'qual_ap' => @qual_ap,
			'storage_location' => @storage_location,
			'forms_present_received' => @forms_present_received,
			'date_forms_adrc' => @date_forms_adrc,
			'forms_received_by' => @forms_received_by,
			'notes_comments' => @notes_comments,
			'changes_in_sample_disposition_disposal' => changes_in_sample_disposition_disposal,
			'displosed_by' => @displosed_by,
			'tubes_with_left_column_ids' => @tubes_with_left_column_ids,
			'transit_days' => @transit_days,
			'age_at_appt' => @age_at_appt

		}
	end

	def to_sql_insert(table_name='cg_mars_samples')
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

# How did I use this?

# mars_data = CSV.read("/Users/wbbevis/Desktop/MARS sample data/MARSv2.csv", :headers => true)
# mars_v2_group = mars_data.select{|item| item["Sample Date"] =~ /\d{4}-\d{2}-\d{2}/ }.map{|item| MarsSampleForm.from_csv(item)}
# connection = ActiveRecord::Base.connection
# mars_v2_group.each{|item| connection.execute(item.to_sql_insert())}



# alter table cg_mars_samples add column seq_run_1 varchar(50);
# alter table cg_mars_samples add column seq_run_2 varchar(50);
# alter table cg_mars_samples add column seq_run_3 varchar(50);

# alter table cg_mars_samples add column tube1_tare varchar(50);
# alter table cg_mars_samples add column tube1_with_sample varchar(50);
# alter table cg_mars_samples add column tube2_tare varchar(50);
# alter table cg_mars_samples add column tube2_with_sample varchar(50);
# alter table cg_mars_samples add column tube3_tare varchar(50);
# alter table cg_mars_samples add column tube3_with_sample varchar(50);
# alter table cg_mars_samples add column dry_tube_tare varchar(50);
# alter table cg_mars_samples add column dry_tube_with_sample varchar(50);
# alter table cg_mars_samples add column dry_tube_dry_sample_a varchar(50);
# alter table cg_mars_samples add column dry_tube_dry_sample_b varchar(50);
# alter table cg_mars_samples add column dry_tube_dry_sample_c varchar(50);
# alter table cg_mars_samples add column sample_dry_matter varchar(50);
# alter table cg_mars_samples add column qual_ap varchar(50);

# alter table cg_mars_samples add column tubes_with_left_column_ids varchar(50);
# alter table cg_mars_samples add column transit_days varchar(50);


