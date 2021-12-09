class WrapAdiForm

	include ActiveModel::Model
	include ActiveModel::Serialization

	attr_accessor :wrapnum, :participant_id
	attr_accessor :adi_natran, :adi_stater, :prim_ruca, :sec_ruca

	def self.attributes
		{
			'wrapnum' => '',
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

		ppt = Participant.where(:reggieid => row['ReggieID']).first

		if !ppt.nil?

			choices['wrapnum'] = ppt.wrapnum
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
