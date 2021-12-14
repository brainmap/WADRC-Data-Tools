class CsfAnalyteSarstedtFreezeForm

	include ActiveModel::Model
	include ActiveModel::Serialization

	attr_accessor :participant_id, :reggieid, :data_source, :age_lp, :sample_date, :run_datetime_ABeta_1_42
	attr_accessor :run_datetime_pTau, :run_datetime_tTau, :ABeta_1_42, :pTau, :tTau, :pTau_ABeta_1_42_derived
	attr_accessor :ABeta_1_42_bin, :pTau_bin, :tTau_bin, :pTau_ABeta_1_42_derived_bin

	validate :validate_reggieid

	def self.attributes
		{
			'participant_id' => nil,
			'reggieid' => '',
			'data_source' => '',
			'age_lp' => nil,
			'sample_date' => nil,
			'run_datetime_ABeta_1_42' => '',
			'run_datetime_pTau' => '',
			'run_datetime_tTau' => '',
			'ABeta_1_42' => '',
			'pTau' => '',
			'tTau' => '',
			'pTau_ABeta_1_42_derived' => '',
			'ABeta_1_42_bin' => '',
			'pTau_bin' => '',
			'tTau_bin' => '',
			'pTau_ABeta_1_42_derived_bin' => ''
		}
	end

	def self.from_csv (row)
		choices = {}

		ppt = Participant.where(:reggieid => row['Reggieid']).first

		if !ppt.nil?

			choices['participant_id'] = ppt.id
			choices['reggieid'] = row['Reggieid']
			choices['data_source'] = row['Data.Source']
			choices['age_lp'] = row['age.lp'].to_f
			choices['sample_date'] = Date.strptime(row["sample_date"].to_s, "%Y-%m-%d")
			choices['run_datetime_ABeta_1_42'] = row['run_datetime_ABeta_1_42'].to_s
			choices['run_datetime_pTau'] = row['run_datetime_pTau'].to_s
			choices['run_datetime_tTau'] = row['run_datetime_tTau'].to_s
			choices['ABeta_1_42'] = row['ABeta_1_42'].to_s
			choices['pTau'] = row['pTau'].to_s
			choices['tTau'] = row['tTau'].to_s
			choices['pTau_ABeta_1_42_derived'] = row['pTau_ABeta_1_42_derived'].to_s
			choices['ABeta_1_42_bin'] = row['ABeta_1_42_bin'].to_s
			choices['pTau_bin'] = row['pTau_bin'].to_s
			choices['tTau_bin'] = row['tTau_bin'].to_s
			choices['pTau_ABeta_1_42_derived_bin'] = row['pTau_ABeta_1_42_derived_bin'].to_s

			return self.new(choices)
		end
		
	end

	def attributes
		{
			'participant_id' => @participant_id,
			'reggieid' => @reggieid,
			'data_source' => @data_source,
			'age_lp' => @age_lp,
			'sample_date' => @sample_date,
			'run_datetime_ABeta_1_42' => @run_datetime_ABeta_1_42,
			'run_datetime_pTau' => @run_datetime_pTau,
			'run_datetime_tTau' => @run_datetime_tTau,
			'ABeta_1_42' => @ABeta_1_42,
			'pTau' => @pTau,
			'tTau' => @tTau,
			'pTau_ABeta_1_42_derived' => @pTau_ABeta_1_42_derived,
			'ABeta_1_42_bin' => @ABeta_1_42_bin,
			'pTau_bin' => @pTau_bin,
			'tTau_bin' => @tTau_bin,
			'pTau_ABeta_1_42_derived_bin' => @pTau_ABeta_1_42_derived_bin
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

	def validate_reggieid
		# this is supposed to tell us if the first column on the input spreadsheet matches an enumber in the Panda
		if Participant.where(:reggieid => @participant_id).first.nil?
			errors.add(:reggieid, "should match an existing reggieid in Panda")
		end
	end

end

# CREATE TABLE `cg_csf_local_roche_sarstedt_freeze_new` (
#   id int NOT NULL AUTO_INCREMENT,
#   participant_id int(11),
#   reggieid varchar(20) DEFAULT NULL,
#   data_source varchar(20) DEFAULT NULL,
#   age_lp float DEFAULT NULL,
#   sample_date date DEFAULT NULL,
#   run_datetime_ABeta_1_42 varchar(40) DEFAULT NULL,
#   run_datetime_pTau varchar(40) DEFAULT NULL,
#   run_datetime_tTau varchar(40) DEFAULT NULL,
#   ABeta_1_42 varchar(20) DEFAULT NULL,
#   pTau varchar(20) DEFAULT NULL,
#   tTau varchar(20) DEFAULT NULL,
#   pTau_ABeta_1_42_derived varchar(20) DEFAULT NULL,
#   ABeta_1_42_bin varchar(20) DEFAULT NULL,
#   pTau_bin varchar(20) DEFAULT NULL,
#   tTau_bin varchar(20) DEFAULT NULL,
#   pTau_ABeta_1_42_derived_bin varchar(20) DEFAULT NULL,
#   PRIMARY KEY (`id`)
# )
