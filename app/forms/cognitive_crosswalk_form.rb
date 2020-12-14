class CognitiveCrosswalkForm

	# 2020-12-14 wbbevis -- I'm using this specifically to import Erin's UP Centiles data

	include ActiveModel::Model
	include ActiveModel::Serialization

	attr_accessor :reggieid, :visit_number, :bnt_xw, :dspb_xw, :dspf_xw, :cfl_xw, :lm_del_xw
	attr_accessor :lm_imm_xw, :mmse_xw, :trlb_xw, :pacc3_cfl_xw_sca, :pacc3_trlb_xw_sca 
	attr_accessor :pacc3_wrap_sca, :pacc4_cfl_trlb_xw_sca, :pacc4_trlb_xw_sca, :pacc4_wrap_sca 
	attr_accessor :pacc5_wrap_sca, :theo_mem_xw_sca, :participant_id

	def self.attributes

		{
			'reggieid' => '',
			'visit_number' => '',
			'bnt_xw' => '',
			'dspb_xw' => '',
			"dspf_xw" => '', 
			"cfl_xw" => '', 
			"lm_del_xw" => '', 
			"lm_imm_xw" => '', 
			"mmse_xw" => '', 
			"trlb_xw" => '', 
			"pacc3_cfl_xw_sca" => '', 
			"pacc3_trlb_xw_sca" => '', 
			"pacc3_wrap_sca" => '', 
			"pacc4_cfl_trlb_xw_sca" => '', 
			"pacc4_trlb_xw_sca" => '', 
			"pacc4_wrap_sca" => '', 
			"pacc5_wrap_sca" => '', 
			"theo_mem_xw_sca" => '',
			"participant_id" => ''
		}
	end

	def self.from_csv (row)
		choices = {}

		choices['reggieid'] = row["Reggieid"].to_s

		choices['participant_id'] = nil
		if !choices['reggieid'].blank?
			participant = Participant.where(:reggieid => choices['reggieid']).first
			if !participant.nil?
				choices['participant_id'] = participant.id
			end
		end

		choices['visit_number'] = row["Visit_Number"].to_s == "NA" ? 'missing' : row["Visit_Number"].to_s
		choices['bnt_xw'] = row["bnt.xw"].to_s == "NA" ? 'missing' : row["bnt.xw"].to_s
		choices['dspb_xw'] = row["dspb.xw"].to_s == "NA" ? 'missing' : row["dspb.xw"].to_s
		choices["dspf_xw"] = row["dspf.xw"].to_s == "NA" ? 'missing' : row["dspf.xw"].to_s
		choices["cfl_xw"] = row["cfl.xw"].to_s == "NA" ? 'missing' : row["cfl.xw"].to_s
		choices["lm_del_xw"] = row["lm_del.xw"].to_s == "NA" ? 'missing' : row["lm_del.xw"].to_s
		choices["lm_imm_xw"] = row["lm_imm.xw"].to_s == "NA" ? 'missing' : row["lm_imm.xw"].to_s
		choices["mmse_xw"] = row["mmse.xw"].to_s == "NA" ? 'missing' : row["mmse.xw"].to_s
		choices["trlb_xw"] = row["trlb.xw"].to_s == "NA" ? 'missing' : row["trlb.xw"].to_s
		choices["pacc3_cfl_xw_sca"] = row["pacc3.cfl.xw.sca"].to_s == "NA" ? 'missing' : row["pacc3.cfl.xw.sca"].to_s
		choices["pacc3_trlb_xw_sca"] = row["pacc3.trlb.xw.sca"].to_s == "NA" ? 'missing' : row["pacc3.trlb.xw.sca"].to_s
		choices["pacc3_wrap_sca"] = row["pacc3.wrap.sca"].to_s == "NA" ? 'missing' : row["pacc3.wrap.sca"].to_s
		choices["pacc4_cfl_trlb_xw_sca"] = row["pacc4.cfl.trlb.xw.sca"].to_s == "NA" ? 'missing' : row["pacc4.cfl.trlb.xw.sca"].to_s
		choices["pacc4_trlb_xw_sca"] = row["pacc4.trlb.xw.sca"].to_s == "NA" ? 'missing' : row["pacc4.trlb.xw.sca"].to_s
		choices["pacc4_wrap_sca"] = row["pacc4.wrap.sca"].to_s == "NA" ? 'missing' : row["pacc4.wrap.sca"].to_s
		choices["pacc5_wrap_sca"] = row["pacc5.wrap.sca"].to_s == "NA" ? 'missing' : row["pacc5.wrap.sca"].to_s
		choices["theo_mem_xw_sca"] = row["theo.mem.xw.sca"].to_s == "NA" ? 'missing' : row["theo.mem.xw.sca"].to_s


		return self.new(choices)
	end

	def attributes
		{
			
			'reggieid' => @reggieid,
			'visit_number' => @visit_number,
			'bnt_xw' => @bnt_xw,
			'dspb_xw' => @dspb_xw,
			"dspf_xw" => @dspf_xw, 
			"cfl_xw" => @cfl_xw, 
			"lm_del_xw" => @lm_del_xw, 
			"lm_imm_xw" => @lm_imm_xw, 
			"mmse_xw" => @mmse_xw, 
			"trlb_xw" => @trlb_xw, 
			"pacc3_cfl_xw_sca" => @pacc3_cfl_xw_sca, 
			"pacc3_trlb_xw_sca" => @pacc3_trlb_xw_sca, 
			"pacc3_wrap_sca" => @pacc3_wrap_sca, 
			"pacc4_cfl_trlb_xw_sca" => @pacc4_cfl_trlb_xw_sca, 
			"pacc4_trlb_xw_sca" => @pacc4_trlb_xw_sca, 
			"pacc4_wrap_sca" => @pacc4_wrap_sca, 
			"pacc5_wrap_sca" => @pacc5_wrap_sca, 
			"theo_mem_xw_sca" => @theo_mem_xw_sca,
			"participant_id" => @participant_id
		}
	end

	def to_sql_insert(table_name='cg_cognitive_crosswalk')
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

# csv = CSV.read("/Users/wbbevis/Desktop/Erin's imports/up_harm_frz21_xw_only_20201211.csv",:headers => true)
# cog_xwalk = csv.map{|item| CognitiveCrosswalkForm.from_csv(item)}
# connection = ActiveRecord::Base.connection
# cog_xwalk.each{|item| connection.execute(item.to_sql_insert())}

# CREATE TABLE `cg_cognitive_crosswalk` (
# `id` int NOT NULL AUTO_INCREMENT,
# `reggieid` varchar(24) DEFAULT NULL,
# `visit_number` varchar(24) DEFAULT NULL,
# `bnt_xw` varchar(24) DEFAULT NULL,
# `dspb_xw` varchar(24) DEFAULT NULL,
# `dspf_xw` varchar(24) DEFAULT NULL,
# `cfl_xw` varchar(24) DEFAULT NULL,
# `lm_del_xw` varchar(24) DEFAULT NULL,
# `lm_imm_xw` varchar(24) DEFAULT NULL,
# `mmse_xw` varchar(24) DEFAULT NULL,
# `trlb_xw` varchar(24) DEFAULT NULL,
# `pacc3_cfl_xw_sca` varchar(24) DEFAULT NULL,
# `pacc3_trlb_xw_sca` varchar(24) DEFAULT NULL,
# `pacc3_wrap_sca` varchar(24) DEFAULT NULL,
# `pacc4_cfl_trlb_xw_sca` varchar(24) DEFAULT NULL,
# `pacc4_trlb_xw_sca` varchar(24) DEFAULT NULL,
# `pacc4_wrap_sca` varchar(24) DEFAULT NULL,
# `pacc5_wrap_sca` varchar(24) DEFAULT NULL,
# `theo_mem_xw_sca` varchar(24) DEFAULT NULL,
# `participant_id` int(11) DEFAULT NULL,
#  PRIMARY KEY (`id`)
#  )
