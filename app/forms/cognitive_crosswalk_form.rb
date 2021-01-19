class CognitiveCrosswalkForm

	# 2020-12-14 wbbevis -- I'm using this specifically to import Erin's UP Centiles data

	include ActiveModel::Model
	include ActiveModel::Serialization

	attr_accessor :reggieid, :visit_number, :bnt_xw, :dspb_xw, :dspf_xw, :cfl_xw, :lm_del_xw
	attr_accessor :lm_imm_xw, :mmse_xw, :trlb_xw
	attr_accessor :pacc3_cfl_xw_sca, :pacc3_trlb_xw_sca, :pacc3_wrap_sca, :pacc3_cfl_xw, :pacc3_cfl_xw_z, :pacc3_trlb_xw, :pacc3_trlb_xw_z, :pacc3_wrap, :pacc3_wrap_sca, :pacc3_wrap_z
	attr_accessor :pacc4_cfl_trlb_xw, :pacc4_cfl_trlb_xw_sca, :pacc4_cfl_trlb_xw_z, :pacc4_trlb_xw, :pacc4_trlb_xw_z, :pacc4_wrap, :pacc4_wrap_z, :pacc4_cfl_trlb_xw_sca, :pacc4_trlb_xw_sca, :pacc4_wrap_sca 
	attr_accessor :pacc5_wrap_sca, :pacc5_wrap, :pacc5_wrap_z
	attr_accessor :theo_mem_xw_sca, :theo_mem_xw, :theo_mem_xw_z
	attr_accessor :participant_id


	attr_accessor :age, :data_source, :orrt_unc_std, :anartraw, :readstn, :animtotraw
	attr_accessor :bnttot, :bnttot30, :cfltot, :craftdre, :crafturs
	attr_accessor :digbacct, :digforct, :digib, :digif, :drraw, :iqdspb, :iqdspf
	attr_accessor :minttots, :mmsetot, :mocatots, :t6raw, :trla, :trlb, :ttotal
	attr_accessor :udsvertin, :waisrtot, :wmsrar, :wmsrar2

	def self.attributes

		{
			'reggieid' => '',
			'age' => '',
			'visit_number' => '',
			'data_source' => '',
			'orrt_unc_std' => '',
			'anartraw' => '',
			'readstn' => '',
			'animtotraw' => '',
			'bnttot' => '',
			'bnttot30' => '',
			'cfltot' => '',
			'craftdre' => '',
			'crafturs' => '',
			'digbacct' => '',
			'digforct' => '',
			'digib' => '',
			'digif' => '',
			'drraw' => '',
			'iqdspb' => '',
			'iqdspf' => '',
			'minttots' => '',
			'mmsetot' => '',
			'mocatots' => '',
			't6raw' => '',
			'trla' => '',
			'trlb' => '',
			'ttotal' => '',
			'udsvertin' => '',
			'waisrtot' => '',
			'wmsrar' => '',
			'wmsrar2' => '',
			'bnt_xw' => '',
			'dspb_xw' => '',
			"dspf_xw" => '', 
			"cfl_xw" => '', 
			"lm_del_xw" => '', 
			"lm_imm_xw" => '', 
			"mmse_xw" => '', 
			"trlb_xw" => '', 
			'pacc3_cfl_xw' => '',
			"pacc3_cfl_xw_sca" => '', 
			'pacc3_cfl_xw_z' => '',
			'pacc3_trlb_xw' => '',
			"pacc3_trlb_xw_sca" => '', 
			'pacc3_trlb_xw_z' => '',
			'pacc3_wrap' => '',
			"pacc3_wrap_sca" => '', 
			'pacc3_wrap_z' => '',
			'pacc4_cfl_trlb_xw' => '',
			"pacc4_cfl_trlb_xw_sca" => '', 
			'pacc4_cfl_trlb_xw_z' => '',
			'pacc4_trlb_xw' => '',
			"pacc4_trlb_xw_sca" => '', 
			'pacc4_trlb_xw_z' => '',
			'pacc4_wrap' => '',
			"pacc4_wrap_sca" => '', 
			'pacc4_wrap_z' => '',
			'pacc5_wrap' => '',
			"pacc5_wrap_sca" => '', 
			'pacc5_wrap_z' => '',
			'theo_mem_xw' => '',
			"theo_mem_xw_sca" => '',
			'theo_mem_xw_z' => '',
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


		choices['age'] = row["age"].to_s == "NA" ? 'missing' : row["Visit_Number"].to_s
		choices['visit_number'] = row["Visit_Number"].to_s == "NA" ? 'missing' : row["Visit_Number"].to_s

		choices['data_source'] = row["Data.Source"].to_s == "NA" ? 'missing' : row["Visit_Number"].to_s
		choices['orrt_unc_std'] = row["ORRT.Unc_Std"].to_s == "NA" ? 'missing' : row["Visit_Number"].to_s
		choices['anartraw'] = row["anartraw"].to_s == "NA" ? 'missing' : row["Visit_Number"].to_s
		choices['readstn'] = row["readstn"].to_s == "NA" ? 'missing' : row["Visit_Number"].to_s
		choices['animtotraw'] = row["animtotraw"].to_s == "NA" ? 'missing' : row["Visit_Number"].to_s
		choices['bnttot'] = row["bnttot"].to_s == "NA" ? 'missing' : row["Visit_Number"].to_s
		choices['bnttot30'] = row["bnttot30"].to_s == "NA" ? 'missing' : row["Visit_Number"].to_s
		choices['cfltot'] = row["cfltot"].to_s == "NA" ? 'missing' : row["Visit_Number"].to_s
		choices['craftdre'] = row["CRAFTDRE"].to_s == "NA" ? 'missing' : row["Visit_Number"].to_s
		choices['crafturs'] = row["CRAFTURS"].to_s == "NA" ? 'missing' : row["Visit_Number"].to_s
		choices['digbacct'] = row["DIGBACCT"].to_s == "NA" ? 'missing' : row["Visit_Number"].to_s
		choices['digforct'] = row["DIGFORCT"].to_s == "NA" ? 'missing' : row["Visit_Number"].to_s
		choices['digib'] = row["DIGIB"].to_s == "NA" ? 'missing' : row["Visit_Number"].to_s
		choices['digif'] = row["DIGIF"].to_s == "NA" ? 'missing' : row["Visit_Number"].to_s
		choices['drraw'] = row["drraw"].to_s == "NA" ? 'missing' : row["Visit_Number"].to_s
		choices['iqdspb'] = row["iqdspb"].to_s == "NA" ? 'missing' : row["Visit_Number"].to_s
		choices['iqdspf'] = row["iqdspf"].to_s == "NA" ? 'missing' : row["Visit_Number"].to_s
		choices['minttots'] = row["MINTTOTS"].to_s == "NA" ? 'missing' : row["Visit_Number"].to_s
		choices['mmsetot'] = row["mmsetot"].to_s == "NA" ? 'missing' : row["Visit_Number"].to_s
		choices['mocatots'] = row["MOCATOTS"].to_s == "NA" ? 'missing' : row["Visit_Number"].to_s
		choices['t6raw'] = row["t6raw"].to_s == "NA" ? 'missing' : row["Visit_Number"].to_s
		choices['trla'] = row["trla"].to_s == "NA" ? 'missing' : row["Visit_Number"].to_s
		choices['trlb'] = row["trlb"].to_s == "NA" ? 'missing' : row["Visit_Number"].to_s
		choices['ttotal'] = row["ttotal"].to_s == "NA" ? 'missing' : row["Visit_Number"].to_s
		choices['udsvertin'] = row["UDSVERTN"].to_s == "NA" ? 'missing' : row["Visit_Number"].to_s
		choices['waisrtot'] = row["waisrtot"].to_s == "NA" ? 'missing' : row["Visit_Number"].to_s
		choices['wmsrar'] = row["wmsrar"].to_s == "NA" ? 'missing' : row["Visit_Number"].to_s
		choices['wmsrar2'] = row["wmsrar2"].to_s == "NA" ? 'missing' : row["Visit_Number"].to_s

		choices['bnt_xw'] = row["bnt.xw"].to_s == "NA" ? 'missing' : row["bnt.xw"].to_s
		choices['dspb_xw'] = row["dspb.xw"].to_s == "NA" ? 'missing' : row["dspb.xw"].to_s
		choices["dspf_xw"] = row["dspf.xw"].to_s == "NA" ? 'missing' : row["dspf.xw"].to_s
		choices["cfl_xw"] = row["cfl.xw"].to_s == "NA" ? 'missing' : row["cfl.xw"].to_s
		choices["lm_del_xw"] = row["lm_del.xw"].to_s == "NA" ? 'missing' : row["lm_del.xw"].to_s
		choices["lm_imm_xw"] = row["lm_imm.xw"].to_s == "NA" ? 'missing' : row["lm_imm.xw"].to_s
		choices["mmse_xw"] = row["mmse.xw"].to_s == "NA" ? 'missing' : row["mmse.xw"].to_s
		choices["trlb_xw"] = row["trlb.xw"].to_s == "NA" ? 'missing' : row["trlb.xw"].to_s

		choices["pacc3_cfl_xw"] = row["pacc3.cfl.xw"].to_s == "NA" ? 'missing' : row["trlb.xw"].to_s
		choices["pacc3_cfl_xw_sca"] = row["pacc3.cfl.xw.sca"].to_s == "NA" ? 'missing' : row["pacc3.cfl.xw.sca"].to_s
		choices["pacc3_cfl_xw_z"] = row["pacc3.cfl.xw.z"].to_s == "NA" ? 'missing' : row["trlb.xw"].to_s
		choices["pacc3_trlb_xw"] = row["pacc3.trlb.xw"].to_s == "NA" ? 'missing' : row["trlb.xw"].to_s
		choices["pacc3_trlb_xw_sca"] = row["pacc3.trlb.xw.sca"].to_s == "NA" ? 'missing' : row["pacc3.trlb.xw.sca"].to_s
		choices["pacc3_trlb_xw_z"] = row["pacc3.trlb.xw.z"].to_s == "NA" ? 'missing' : row["trlb.xw"].to_s
		choices["pacc3_wrap"] = row["pacc3.wrap"].to_s == "NA" ? 'missing' : row["trlb.xw"].to_s
		choices["pacc3_wrap_sca"] = row["pacc3.wrap.sca"].to_s == "NA" ? 'missing' : row["pacc3.wrap.sca"].to_s
		choices["pacc3_wrap_z"] = row["pacc3.wrap.z"].to_s == "NA" ? 'missing' : row["trlb.xw"].to_s
		choices["pacc4_cfl_trlb_xw"] = row["pacc4.cfl.trlb.xw"].to_s == "NA" ? 'missing' : row["trlb.xw"].to_s
		choices["pacc4_cfl_trlb_xw_sca"] = row["pacc4.cfl.trlb.xw.sca"].to_s == "NA" ? 'missing' : row["pacc4.cfl.trlb.xw.sca"].to_s
		choices["pacc4_cfl_trlb_xw_z"] = row["pacc4.cfl.trlb.xw.z"].to_s == "NA" ? 'missing' : row["trlb.xw"].to_s
		choices["pacc4_trlb_xw"] = row["pacc4.trlb.xw"].to_s == "NA" ? 'missing' : row["trlb.xw"].to_s
		choices["pacc4_trlb_xw_sca"] = row["pacc4.trlb.xw.sca"].to_s == "NA" ? 'missing' : row["pacc4.trlb.xw.sca"].to_s
		choices["pacc4_trlb_xw_z"] = row["pacc4.trlb.xw.z"].to_s == "NA" ? 'missing' : row["trlb.xw"].to_s
		choices["pacc4_wrap"] = row["pacc4.wrap"].to_s == "NA" ? 'missing' : row["trlb.xw"].to_s
		choices["pacc4_wrap_sca"] = row["pacc4.wrap.sca"].to_s == "NA" ? 'missing' : row["pacc4.wrap.sca"].to_s
		choices["pacc4_wrap_z"] = row["pacc4.wrap.z"].to_s == "NA" ? 'missing' : row["trlb.xw"].to_s
		choices["pacc5_wrap"] = row["pacc5.wrap"].to_s == "NA" ? 'missing' : row["trlb.xw"].to_s
		choices["pacc5_wrap_sca"] = row["pacc5.wrap.sca"].to_s == "NA" ? 'missing' : row["pacc5.wrap.sca"].to_s
		choices["pacc5_wrap_z"] = row["pacc5.wrap.z"].to_s == "NA" ? 'missing' : row["trlb.xw"].to_s
		choices["theo_mem_xw"] = row["theo.mem.xw"].to_s == "NA" ? 'missing' : row["trlb.xw"].to_s
		choices["theo_mem_xw_sca"] = row["theo.mem.xw.sca"].to_s == "NA" ? 'missing' : row["theo.mem.xw.sca"].to_s
		choices["theo_mem_xw_z"] = row["theo.mem.xw.z"].to_s == "NA" ? 'missing' : row["trlb.xw"].to_s


		return self.new(choices)
	end

	def attributes
		{
			
			'reggieid' => @reggieid,
			'age' => @age,
			'visit_number' => @visit_number,
			'data_source' => @data_source,
			'orrt_unc_std' => @orrt_unc_std,
			'anartraw' => @anartraw,
			'readstn' => @readstn,
			'animtotraw' => @animtotraw,
			'bnttot' => @bnttot,
			'bnttot30' => @bnttot30,
			'cfltot' => @cfltot,
			'craftdre' => @craftdre,
			'crafturs' => @crafturs,
			'digbacct' => @digbacct,
			'digforct' => @digforct,
			'digib' => @digib,
			'digif' => @digif,
			'drraw' => @drraw,
			'iqdspb' => @iqdspb,
			'iqdspf' => @iqdspf,
			'minttots' => @minttots,
			'mmsetot' => @mmsetot,
			'mocatots' => @mocatots,
			't6raw' => @t6raw,
			'trla' => @trla,
			'trlb' => @trlb,
			'ttotal' => @ttotal,
			'udsvertin' => @udsvertin,
			'waisrtot' => @waisrtot,
			'wmsrar' => @wmsrar,
			'wmsrar2' => @wmsrar2,
			'bnt_xw' => @bnt_xw,
			'dspb_xw' => @dspb_xw,
			"dspf_xw" => @dspf_xw, 
			"cfl_xw" => @cfl_xw, 
			"lm_del_xw" => @lm_del_xw, 
			"lm_imm_xw" => @lm_imm_xw, 
			"mmse_xw" => @mmse_xw, 
			"trlb_xw" => @trlb_xw, 

			'pacc3_cfl_xw' => @pacc3_cfl_xw,
			"pacc3_cfl_xw_sca" => @pacc3_cfl_xw_sca, 
			'pacc3_cfl_xw_z' => @pacc3_cfl_xw_z,
			'pacc3_trlb_xw' => @pacc3_trlb_xw,
			"pacc3_trlb_xw_sca" => @pacc3_trlb_xw_sca, 
			'pacc3_trlb_xw_z' => @pacc3_trlb_xw_z,
			'pacc3_wrap' => @pacc3_wrap,
			"pacc3_wrap_sca" => @pacc3_wrap_sca, 
			'pacc3_wrap_z' => @pacc3_wrap_z,
			'pacc4_cfl_trlb_xw' => @pacc4_cfl_trlb_xw,
			"pacc4_cfl_trlb_xw_sca" => @pacc4_cfl_trlb_xw_sca, 
			'pacc4_cfl_trlb_xw_z' => @pacc4_cfl_trlb_xw_z,
			'pacc4_trlb_xw' => @pacc4_trlb_xw,
			"pacc4_trlb_xw_sca" => @pacc4_trlb_xw_sca, 
			'pacc4_trlb_xw_z' => @pacc4_trlb_xw_z,
			'pacc4_wrap' => @pacc4_wrap,
			"pacc4_wrap_sca" => @pacc4_wrap_sca, 
			'pacc4_wrap_z' => @pacc4_wrap_z,
			'pacc5_wrap' => @pacc5_wrap,
			"pacc5_wrap_sca" => @pacc5_wrap_sca, 
			'pacc5_wrap_z' => @pacc5_wrap_z,
			'theo_mem_xw' => @theo_mem_xw,
			"theo_mem_xw_sca" => @theo_mem_xw_sca,
			'theo_mem_xw_z' => @theo_mem_xw_z,
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

# csv = CSV.read("/Users/wbbevis/Desktop/Erin's imports/up_harm_frz21_xw_z_sca_20210118.csv",:headers => true)
# cog_xwalk = csv.map{|item| CognitiveCrosswalkForm.from_csv(item)}
# connection = ActiveRecord::Base.connection
# cog_xwalk.each{|item| connection.execute(item.to_sql_insert())}


# drop table cg_cognitive_crosswalk;
# CREATE TABLE `cg_cognitive_crosswalk` (
# `id` int NOT NULL AUTO_INCREMENT,
# `reggieid` varchar(24) DEFAULT NULL,
# `age` float DEFAULT NULL,
# `visit_number` varchar(24) DEFAULT NULL,
# `data_source` varchar(24) DEFAULT NULL,
# `orrt_unc_std` varchar(24) DEFAULT NULL,
# `anartraw` varchar(24) DEFAULT NULL,
# `readstn` varchar(24) DEFAULT NULL,
# `animtotraw` varchar(24) DEFAULT NULL,
# `bnttot` varchar(24) DEFAULT NULL,
# `bnttot30` varchar(24) DEFAULT NULL,
# `cfltot` varchar(24) DEFAULT NULL,
# `craftdre` varchar(24) DEFAULT NULL,
# `crafturs` varchar(24) DEFAULT NULL,
# `digbacct` varchar(24) DEFAULT NULL,
# `digforct` varchar(24) DEFAULT NULL,
# `digib` varchar(24) DEFAULT NULL,
# `digif` varchar(24) DEFAULT NULL,
# `drraw` varchar(24) DEFAULT NULL,
# `iqdspb` varchar(24) DEFAULT NULL,
# `iqdspf` varchar(24) DEFAULT NULL,
# `minttots` varchar(24) DEFAULT NULL,
# `mmsetot` varchar(24) DEFAULT NULL,
# `mocatots` varchar(24) DEFAULT NULL,
# `t6raw` varchar(24) DEFAULT NULL,
# `trla` varchar(24) DEFAULT NULL,
# `trlb` varchar(24) DEFAULT NULL,
# `ttotal` varchar(24) DEFAULT NULL,
# `udsvertin` varchar(24) DEFAULT NULL,
# `waisrtot` varchar(24) DEFAULT NULL,
# `wmsrar` varchar(24) DEFAULT NULL,
# `wmsrar2` varchar(24) DEFAULT NULL,
# `bnt_xw` varchar(24) DEFAULT NULL,
# `dspb_xw` varchar(24) DEFAULT NULL,
# `dspf_xw`  varchar(24) DEFAULT NULL,
# `cfl_xw`  varchar(24) DEFAULT NULL,
# `lm_del_xw`  varchar(24) DEFAULT NULL,
# `lm_imm_xw`  varchar(24) DEFAULT NULL,
# `mmse_xw`  varchar(24) DEFAULT NULL,
# `trlb_xw`  varchar(24) DEFAULT NULL,
# `pacc3_cfl_xw` varchar(24) DEFAULT NULL,
# `pacc3_cfl_xw_sca`  varchar(24) DEFAULT NULL,
# `pacc3_cfl_xw_z` varchar(24) DEFAULT NULL,
# `pacc3_trlb_xw` varchar(24) DEFAULT NULL,
# `pacc3_trlb_xw_sca`  varchar(24) DEFAULT NULL,
# `pacc3_trlb_xw_z` varchar(24) DEFAULT NULL,
# `pacc3_wrap` varchar(24) DEFAULT NULL,
# `pacc3_wrap_sca`  varchar(24) DEFAULT NULL,
# `pacc3_wrap_z` varchar(24) DEFAULT NULL,
# `pacc4_cfl_trlb_xw` varchar(24) DEFAULT NULL,
# `pacc4_cfl_trlb_xw_sca`  varchar(24) DEFAULT NULL,
# `pacc4_cfl_trlb_xw_z` varchar(24) DEFAULT NULL,
# `pacc4_trlb_xw` varchar(24) DEFAULT NULL,
# `pacc4_trlb_xw_sca`  varchar(24) DEFAULT NULL,
# `pacc4_trlb_xw_z` varchar(24) DEFAULT NULL,
# `pacc4_wrap` varchar(24) DEFAULT NULL,
# `pacc4_wrap_sca`  varchar(24) DEFAULT NULL,
# `pacc4_wrap_z` varchar(24) DEFAULT NULL,
# `pacc5_wrap` varchar(24) DEFAULT NULL,
# `pacc5_wrap_sca`  varchar(24) DEFAULT NULL,
# `pacc5_wrap_z` varchar(24) DEFAULT NULL,
# `theo_mem_xw` varchar(24) DEFAULT NULL,
# `theo_mem_xw_sca` varchar(24) DEFAULT NULL,
# `theo_mem_xw_z` varchar(24) DEFAULT NULL,
# `participant_id` int(11) DEFAULT NULL,
#  PRIMARY KEY (`id`)
#  )

