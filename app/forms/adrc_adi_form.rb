class AdrcAdiForm

	include ActiveModel::Model
	include ActiveModel::Serialization

	attr_accessor :adrcnum, :reggieid, :participant_id
	attr_accessor :adi_natran, :adi_stater, :prim_ruca, :sec_ruca

	def self.attributes
		{
			'adrcnum' => '',
			'reggieid' => '',
			'participant_id' => '',
			'adi_natran' => '',
			'adi_stater' => '',
			'prim_ruca' => '',
			'sec_ruca' => ''
		}
	end

	def self.from_csv (row)
		choices = {}

		# look up a participant with a matching reggieid and adrcnumber

		ppt = Participant.where(:adrcnum => row['ptid']).where(:reggieid => row['id']).first

		if !ppt.nil?

			choices['adrcnum'] = ppt.adrcnum
			choices['reggieid'] = ppt.reggieid
			choices['participant_id'] = ppt.id
			choices['adi_natran'] = row['ADI_NATRAN']
			choices['adi_stater'] = row['ADI_STATER']
			choices['prim_ruca'] = row['PRIM_RUCA']
			choices['sec_ruca'] = row['SEC_RUCA']

			return self.new(choices)
		else
			# raise an exception, and catch it in the import job
		end

	end

	def attributes
		{
			'wrapnum' => @wrapnum,
			'reggieid' => @reggieid,
			'participant_id' => @participant_id,
			'adi_natran' => @adi_natran,
			'adi_stater' => @adi_stater,
			'prim_ruca' => @prim_ruca,
			'sec_ruca' => @sec_ruca
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

# CREATE TABLE `cg_lst_lpa` (
#   `id` int NOT NULL AUTO_INCREMENT,
#   `wrapnum` varchar(20) DEFAULT NULL,
#   `adrcnum` varchar(20) DEFAULT NULL,
#   `participant_id` int(11),
#   `adi_natran` varchar(255) DEFAULT NULL,
#   `adi_stater` varchar(255) DEFAULT NULL,
#   `prim_ruca` varchar(255) DEFAULT NULL,
#   `sec_ruca` varchar(255) DEFAULT NULL,
#   PRIMARY KEY (`id`)
# )
