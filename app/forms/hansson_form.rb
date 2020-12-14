class HanssonForm

	# 2020-12-14 wbbevis -- I'm using this specifically to import Erin's Hansson picklist

	include ActiveModel::Model
	include ActiveModel::Serialization

	attr_accessor :wrapno, :dbid, :reggieid, :visno, :dt_blood, :age_at_blood
	attr_accessor :participant_id

	# ["WRAPNo", "DBID", "Reggieid", "VisNo", "dtBlood", "AgeAtBlood"]

	def self.attributes
		{
			'wrapno' => '',
			'dbid' => '',
			'reggieid' => '',
			'dt_blood' => '',
			'age_at_blood' => '',
			'reggieid' => '',
			'participant_id' => ''
		}
	end

	def self.from_csv (row)
		choices = {}

		choices['wrapno'] = row["WRAPNo"].to_s
		choices["dbid"] = row["WRAPNo"].to_s
		
		choices['reggieid'] = row["Reggieid"].to_s
		choices['participant_id'] = nil
		if !choices['reggieid'].blank?
			participant = Participant.where(:reggieid => choices['reggieid']).first
			if !participant.nil?
				choices['participant_id'] = participant.id
			end
		end

		choices["visno"] = row["VisNo"].to_i
		choices["dt_blood"] = row["dtBlood"].blank? ? nil : Date.strptime(row["dtBlood"].to_s)
		choices["age_at_blood"] = row["AgeAtBlood"].to_f

		return self.new(choices)
	end

	def attributes
		{
			
			'wrapno' => @wrapno,
			'dbid' => @dbid,
			'reggieid' => @reggieid,
			'dt_blood' => @dt_blood,
			'age_at_blood' => @age_at_blood,
			'reggieid' => @reggieid,
			'participant_id' => @participant_id
		}
	end

	def to_sql_insert(table_name='cg_hansson_manifest')
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

# csv = CSV.read("/Users/wbbevis/Desktop/Erin's imports/hansson_picklist_20201201.csv",:headers => true)
# hansson_manifest = csv.map{|item| HanssonForm.from_csv(item)}
# connection = ActiveRecord::Base.connection
# hansson_manifest.each{|item| connection.execute(item.to_sql_insert())}

# CREATE TABLE `cg_hansson_manifest` (
# `id` int NOT NULL AUTO_INCREMENT,
#   `wrapno` varchar(5) DEFAULT NULL,
#   `dbid` varchar(10) DEFAULT NULL,
#   `reggieid` varchar(24) DEFAULT NULL,
#   `visno` int(11) DEFAULT NULL,
#   `dt_blood` date DEFAULT NULL,
#   `participant_id` int(11) DEFAULT NULL,
#   `age_at_blood` float DEFAULT NULL,
#   PRIMARY KEY (`id`)
# )
