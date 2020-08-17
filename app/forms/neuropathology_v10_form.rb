class NeuropathologyV10Form

	include ActiveModel::Model
	include ActiveModel::Serialization

	# for matching these to a participant
	attr_accessor :enumber, :reggie_id, :participant_id

	# v10 fields
	attr_accessor :ptid, :npformmo, :npformdy, :npformyr, :npid, :npsex, :npdage, :npdodmo, :npdoddy, :npdodyr 
	attr_accessor :nppmih, :npfix, :npfixx, :npwbrwt, :npwbrf, :npgrcca, :npgrla, :npgrha, :npgrsnh, :npgrlch, :npavas, :nptan
	attr_accessor :nptanx, :npaban, :npabanx, :npasan, :npasanx, :nptdpan, :nptdpanx, :nphismb, :nphisg, :nphisss, :nphist
	attr_accessor :nphiso, :nphisox, :npthal, :npbraak, :npneur, :npadnc, :npdiff, :npamy, :npinf, :npinf1a, :npinf1b, :npinf1d
	attr_accessor :npinf1f, :npinf2a, :npinf2b, :npinf2d, :npinf2f, :npinf3a, :npinf3b, :npinf3d, :npinf3f, :npinf4a, :npinf4b
	attr_accessor :npinf4d, :npinf4f, :nphemo, :nphemo1, :nphemo2, :nphemo3, :npold, :npold1, :npold2, :npold3, :npold4, :npoldd
	attr_accessor :npoldd1, :npoldd2, :npoldd3, :npoldd4, :nparter, :npwmr, :nppath, :npnec, :nppath2, :nppath3, :nppath4, :nppath5
	attr_accessor :nppath6, :nppath7, :nppath8, :nppath9, :nppath10, :nppath11, :nppatho, :nppathox, :nplbod, :npnloss, :nphipscl
	attr_accessor :nptdpa, :nptdpb, :nptdpc, :nptdpd, :nptdpe, :npftdtau, :nppick, :npftdt2, :npcort, :npprog, :npftdt5, :npftdt6
	attr_accessor :npftdt7, :npftdt8, :npftdt9, :npftdt10, :npftdtdp, :npalsmnd, :npoftd, :npoftd1, :npoftd2, :npoftd3, :npoftd4
	attr_accessor :npoftd5, :nppdxa, :nppdxb, :nppdxc, :nppdxd, :nppdxe, :nppdxf, :nppdxg, :nppdxh, :nppdxi, :nppdxj, :nppdxk
	attr_accessor :nppdxl, :nppdxm, :nppdxn, :nppdxo, :nppdxp, :nppdxq, :nppdxr, :nppdxrx, :nppdxs, :nppdxsx, :nppdxt, :nppdxtx
	attr_accessor :npbnka, :npbnkb, :npbnkc, :npbnkd, :npbnke, :npbnkf, :npbnkg, :npfaut, :npfaut1, :npfaut2, :npfaut3, :npfaut4
	attr_accessor :age_at_death


	validate :validate_enumber

	# v9 legacy fields that we should map
	# attr_accessor :npgross, :npnit, :npcerad, :npadrda, :npocrit, :npvasc, :nplinf, :npmicro, :nplac, :nphem, :npart, 
	# attr_accessor :npscl, :npoang, :nplewy, :npfront, :nptau, :npftd, :npftdno, :npftdspc, :npcj, :npprion, :npmajor, :npmpath2, 
	# attr_accessor :npfhspec, :npapoe, :npvoth, :nplewycs, :npgene, :nptauhap, :npprnp, :npchrom, :npbrfrzn, :npbrfrm, :npbparf, :npcsfant

	def self.attributes
		{
			'enumber' => nil,'reggie_id' => nil,'participant_id' => nil, 'ptid' => nil, 'npformmo' => nil, 'npformdy' => nil, 'npformyr' => nil, 
			'npid' => nil, 'npsex' => nil, 'npdage' => nil, 'npdodmo' => nil, 
			'npdoddy' => nil, 'npdodyr' => nil, 'nppmih' => nil, 'npfix' => nil, 
			'npfixx' => nil, 'npwbrwt' => nil, 'npwbrf' => nil, 'npgrcca' => nil, 'npgrla' => nil, 'npgrha' => nil, 
			'npgrsnh' => nil, 'npgrlch' => nil, 'npavas' => nil, 'nptan' => nil, 'nptanx' => nil, 'npaban' => nil, 
			'npabanx' => nil, 'npasan' => nil, 'npasanx' => nil, 'nptdpan' => nil, 'nptdpanx' => nil, 'nphismb' => nil, 
			'nphisg' => nil, 'nphisss' => nil, 'nphist' => nil, 'nphiso' => nil, 'nphisox' => nil, 'npthal' => nil, 
			'npbraak' => nil, 'npneur' => nil, 'npadnc' => nil, 'npdiff' => nil, 'npamy' => nil, 'npinf' => nil, 
			'npinf1a' => nil, 'npinf1b' => nil, 'npinf1d' => nil, 'npinf1f' => nil, 'npinf2a' => nil, 'npinf2b' => nil, 
			'npinf2d' => nil, 'npinf2f' => nil, 'npinf3a' => nil, 'npinf3b' => nil, 'npinf3d' => nil, 'npinf3f' => nil, 
			'npinf4a' => nil, 'npinf4b' => nil, 'npinf4d' => nil, 'npinf4f' => nil, 'nphemo' => nil, 'nphemo1' => nil, 
			'nphemo2' => nil, 'nphemo3' => nil, 'npold' => nil, 'npold1' => nil, 'npold2' => nil, 'npold3' => nil, 
			'npold4' => nil, 'npoldd' => nil, 'npoldd1' => nil, 'npoldd2' => nil, 'npoldd3' => nil, 'npoldd4' => nil, 
			'nparter' => nil, 'npwmr' => nil, 'nppath' => nil, 
			'npnec' => nil, 'nppath2' => nil, 'nppath3' => nil, 'nppath4' => nil, 'nppath5' => nil, 'nppath6' => nil, 
			'nppath7' => nil, 'nppath8' => nil, 'nppath9' => nil, 'nppath10' => nil, 'nppath11' => nil, 'nppatho' => nil, 
			'nppathox' => nil, 'nplbod' => nil, 'npnloss' => nil, 'nphipscl' => nil, 'nptdpa' => nil, 'nptdpb' => nil, 
			'nptdpc' => nil, 'nptdpd' => nil, 'nptdpe' => nil, 'npftdtau' => nil, 'nppick' => nil, 'npftdt2' => nil, 
			'npcort' => nil, 'npprog' => nil, 'npftdt5' => nil, 'npftdt6' => nil, 'npftdt7' => nil, 'npftdt8' => nil, 
			'npftdt9' => nil, 'npftdt10' => nil, 'npftdtdp' => nil, 'npalsmnd' => nil, 'npoftd' => nil, 'npoftd1' => nil, 
			'npoftd2' => nil, 'npoftd3' => nil, 'npoftd4' => nil, 'npoftd5' => nil, 'nppdxa' => nil, 'nppdxb' => nil, 
			'nppdxc' => nil, 'nppdxd' => nil, 'nppdxe' => nil, 'nppdxf' => nil, 'nppdxg' => nil, 'nppdxh' => nil, 
			'nppdxi' => nil, 'nppdxj' => nil, 'nppdxk' => nil, 'nppdxl' => nil, 'nppdxm' => nil, 'nppdxn' => nil, 
			'nppdxo' => nil, 'nppdxp' => nil, 'nppdxq' => nil, 'nppdxr' => nil, 'nppdxrx' => nil, 'nppdxs' => nil, 
			'nppdxsx' => nil, 'nppdxt' => nil, 'nppdxtx' => nil, 'npbnka' => nil, 'npbnkb' => nil, 'npbnkc' => nil, 
			'npbnkd' => nil, 'npbnke' => nil, 'npbnkf' => nil, 'npbnkg' => nil, 'npfaut' => nil, 'npfaut1' => nil, 
			'npfaut2' => nil, 'npfaut3' => nil, 'npfaut4' => nil, 'age_at_death' => nil

			# v9 legacy fields that we should map
			# 'npgross' => nil, 'npnit' => nil, 'npcerad' => nil, 'npadrda' => nil, 'npocrit' => nil, 'npvasc' => nil, 
			# 'nplinf' => nil, 'npmicro' => nil, 'nplac' => nil, 'nphem' => nil, 'npart' => nil, 'npscl' => nil, 
			# 'npoang' => nil, 'nplewy' => nil, 'npfront' => nil, 'nptau' => nil, 'npftd' => nil, 'npftdno' => nil, 
			# 'npftdspc' => nil, 'npcj' => nil, 'npprion' => nil, 'npmajor' => nil, 'npmpath2' => nil, 'npfhspec' => nil, 
			# 'npapoe' => nil, 'npvoth' => nil, 'nplewycs' => nil, 'npgene' => nil, 'nptauhap' => nil, 'npprnp' => nil, 
			# 'npchrom' => nil, 'npbrfrzn' => nil, 'npbrfrm' => nil, 'npbparf' => nil, 'npcsfant' => nil

		}
	end


	def self.from_json (json)
		choices = {}

		choices['ptid'] = json['ptid']
		choices['npformmo'] = json['npformmo']
		choices['npformdy'] = json['npformdy']
		choices['npformyr'] = json['npformyr']
		choices['npid'] = json['npid']
		choices['npsex'] = json['npsex']
		choices['npdage'] = json['npdage']
		choices['npdodmo'] = json['npdodmo']
		choices['npdoddy'] = json['npdoddy']
		choices['npdodyr'] = json['npdodyr']
		choices['nppmih'] = json['nppmih']
		choices['npfix'] = json['npfix']
		choices['npfixx'] = json['npfixx']
		choices['npwbrwt'] = json['npwbrwt']
		choices['npwbrf'] = json['npwbrf']
		choices['npgrcca'] = json['npgrcca']
		choices['npgrla'] = json['npgrla']
		choices['npgrha'] = json['npgrha']
		choices['npgrsnh'] = json['npgrsnh']
		choices['npgrlch'] = json['npgrlch']
		choices['npavas'] = json['npavas']
		choices['nptan'] = json['nptan']
		choices['nptanx'] = json['nptanx']
		choices['npaban'] = json['npaban']
		choices['npabanx'] = json['npabanx']
		choices['npasan'] = json['npasan']
		choices['npasanx'] = json['npasanx']
		choices['nptdpan'] = json['nptdpan']
		choices['nptdpanx'] = json['nptdpanx']
		choices['nphismb'] = json['nphismb']
		choices['nphisg'] = json['nphisg']
		choices['nphisss'] = json['nphisss']
		choices['nphist'] = json['nphist']
		choices['nphiso'] = json['nphiso']
		choices['nphisox'] = json['nphisox']
		choices['npthal'] = json['npthal']
		choices['npbraak'] = json['npbraak']
		choices['npneur'] = json['npneur']
		choices['npadnc'] = json['npadnc']
		choices['npdiff'] = json['npdiff']
		choices['npamy'] = json['npamy']
		choices['npinf'] = json['npinf']
		choices['npinf1a'] = json['npinf1a']
		choices['npinf1b'] = json['npinf1b']
		choices['npinf1d'] = json['npinf1d']
		choices['npinf1f'] = json['npinf1f']
		choices['npinf2a'] = json['npinf2a']
		choices['npinf2b'] = json['npinf2b']
		choices['npinf2d'] = json['npinf2d']
		choices['npinf2f'] = json['npinf2f']
		choices['npinf3a'] = json['npinf3a']
		choices['npinf3b'] = json['npinf3b']
		choices['npinf3d'] = json['npinf3d']
		choices['npinf3f'] = json['npinf3f']
		choices['npinf4a'] = json['npinf4a']
		choices['npinf4b'] = json['npinf4b']
		choices['npinf4d'] = json['npinf4d']
		choices['npinf4f'] = json['npinf4f']
		choices['nphemo'] = json['nphemo']
		choices['nphemo1'] = json['nphemo1']
		choices['nphemo2'] = json['nphemo2']
		choices['nphemo3'] = json['nphemo3']
		choices['npold'] = json['npold']
		choices['npold1'] = json['npold1']
		choices['npold2'] = json['npold2']
		choices['npold3'] = json['npold3']
		choices['npold4'] = json['npold4']
		choices['npoldd'] = json['npoldd']
		choices['npoldd1'] = json['npoldd1']
		choices['npoldd2'] = json['npoldd2']
		choices['npoldd3'] = json['npoldd3']
		choices['npoldd4'] = json['npoldd4']
		choices['nparter'] = json['nparter']
		choices['npwmr'] = json['npwmr']
		choices['nppath'] = json['nppath']
		choices['npnec'] = json['npnec']
		choices['nppath2'] = json['nppath2']
		choices['nppath3'] = json['nppath3']
		choices['nppath4'] = json['nppath4']
		choices['nppath5'] = json['nppath5']
		choices['nppath6'] = json['nppath6']
		choices['nppath7'] = json['nppath7']
		choices['nppath8'] = json['nppath8']
		choices['nppath9'] = json['nppath9']
		choices['nppath10'] = json['nppath10']
		choices['nppath11'] = json['nppath11']
		choices['nppatho'] = json['nppatho']
		choices['nppathox'] = json['nppathox']
		choices['nplbod'] = json['nplbod']
		choices['npnloss'] = json['npnloss']
		choices['nphipscl'] = json['nphipscl']
		choices['nptdpa'] = json['nptdpa']
		choices['nptdpb'] = json['nptdpb']
		choices['nptdpc'] = json['nptdpc']
		choices['nptdpd'] = json['nptdpd']
		choices['nptdpe'] = json['nptdpe']
		choices['npftdtau'] = json['npftdtau']
		choices['nppick'] = json['nppick']
		choices['npftdt2'] = json['npftdt2']
		choices['npcort'] = json['npcort']
		choices['npprog'] = json['npprog']
		choices['npftdt5'] = json['npftdt5']
		choices['npftdt6'] = json['npftdt6']
		choices['npftdt7'] = json['npftdt7']
		choices['npftdt8'] = json['npftdt8']
		choices['npftdt9'] = json['npftdt9']
		choices['npftdt10'] = json['npftdt10']
		choices['npftdtdp'] = json['npftdtdp']
		choices['npalsmnd'] = json['npalsmnd']
		choices['npoftd'] = json['npoftd']
		choices['npoftd1'] = json['npoftd1']
		choices['npoftd2'] = json['npoftd2']
		choices['npoftd3'] = json['npoftd3']
		choices['npoftd4'] = json['npoftd4']
		choices['npoftd5'] = json['npoftd5']
		choices['nppdxa'] = json['nppdxa']
		choices['nppdxb'] = json['nppdxb']
		choices['nppdxc'] = json['nppdxc']
		choices['nppdxd'] = json['nppdxd']
		choices['nppdxe'] = json['nppdxe']
		choices['nppdxf'] = json['nppdxf']
		choices['nppdxg'] = json['nppdxg']
		choices['nppdxh'] = json['nppdxh']
		choices['nppdxi'] = json['nppdxi']
		choices['nppdxj'] = json['nppdxj']
		choices['nppdxk'] = json['nppdxk']
		choices['nppdxl'] = json['nppdxl']
		choices['nppdxm'] = json['nppdxm']
		choices['nppdxn'] = json['nppdxn']
		choices['nppdxo'] = json['nppdxo']
		choices['nppdxp'] = json['nppdxp']
		choices['nppdxq'] = json['nppdxq']
		choices['nppdxr'] = json['nppdxr']
		choices['nppdxrx'] = json['nppdxrx']
		choices['nppdxs'] = json['nppdxs']
		choices['nppdxsx'] = json['nppdxsx']
		choices['nppdxt'] = json['nppdxt']
		choices['nppdxtx'] = json['nppdxtx']
		choices['npbnka'] = json['npbnka']
		choices['npbnkb'] = json['npbnkb']
		choices['npbnkc'] = json['npbnkc']
		choices['npbnkd'] = json['npbnkd']
		choices['npbnke'] = json['npbnke']
		choices['npbnkf'] = json['npbnkf']
		choices['npbnkg'] = json['npbnkg']
		choices['npfaut'] = json['npfaut']
		choices['npfaut1'] = json['npfaut1']
		choices['npfaut2'] = json['npfaut2']
		choices['npfaut3'] = json['npfaut3']
		choices['npfaut4'] = json['npfaut4']

		enrollment = Enrollment.where(:enumber => json['ptid']).first

		if !enrollment.nil?
			participant = enrollment.participant
			choices['enumber'] = enrollment.enumber
			choices['participant_id'] = enrollment.participant_id
			choices['reggie_id'] = participant.reggieid

			ppt = Participant.where(:id => enrollment.participant_id).first
			if !ppt.nil?
				dod = Date.new(json['npdodyr'].to_i, json['npdodmo'].to_i, json['npdoddy'].to_i)
				choices['age_at_death'] = ((dod - ppt.dob) / 365.25).round(2)
			end
		end

		return self.new(choices)
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

	def attributes
		{
		 	'enumber' => @enumber,
		 	'reggie_id' => @reggie_id,
			'participant_id' => @participant_id,
			'ptid' => @ptid,
			'npformmo' => @npformmo,
			'npformdy' => @npformdy,
			'npformyr' => @npformyr,
			'npid' => @npid,
			'npsex' => @npsex,
			'npdage' => @npdage,
			'npdodmo' => @npdodmo,
			'npdoddy' => @npdoddy,
			'npdodyr' => @npdodyr,
			'nppmih' => @nppmih,
			'npfix' => @npfix,
			'npfixx' => @npfixx,
			'npwbrwt' => @npwbrwt,
			'npwbrf' => @npwbrf,
			'npgrcca' => @npgrcca,
			'npgrla' => @npgrla,
			'npgrha' => @npgrha,
			'npgrsnh' => @npgrsnh,
			'npgrlch' => @npgrlch,
			'npavas' => @npavas,
			'nptan' => @nptan,
			'nptanx' => @nptanx,
			'npaban' => @npaban,
			'npabanx' => @npabanx,
			'npasan' => @npasan,
			'npasanx' => @npasanx,
			'nptdpan' => @nptdpan,
			'nptdpanx' => @nptdpanx,
			'nphismb' => @nphismb,
			'nphisg' => @nphisg,
			'nphisss' => @nphisss,
			'nphist' => @nphist,
			'nphiso' => @nphiso,
			'nphisox' => @nphisox,
			'npthal' => @npthal,
			'npbraak' => @npbraak,
			'npneur' => @npneur,
			'npadnc' => @npadnc,
			'npdiff' => @npdiff,
			'npamy' => @npamy,
			'npinf' => @npinf,
			'npinf1a' => @npinf1a,
			'npinf1b' => @npinf1b,
			'npinf1d' => @npinf1d,
			'npinf1f' => @npinf1f,
			'npinf2a' => @npinf2a,
			'npinf2b' => @npinf2b,
			'npinf2d' => @npinf2d,
			'npinf2f' => @npinf2f,
			'npinf3a' => @npinf3a,
			'npinf3b' => @npinf3b,
			'npinf3d' => @npinf3d,
			'npinf3f' => @npinf3f,
			'npinf4a' => @npinf4a,
			'npinf4b' => @npinf4b,
			'npinf4d' => @npinf4d,
			'npinf4f' => @npinf4f,
			'nphemo' => @nphemo,
			'nphemo1' => @nphemo1,
			'nphemo2' => @nphemo2,
			'nphemo3' => @nphemo3,
			'npold' => @npold,
			'npold1' => @npold1,
			'npold2' => @npold2,
			'npold3' => @npold3,
			'npold4' => @npold4,
			'npoldd' => @npoldd,
			'npoldd1' => @npoldd1,
			'npoldd2' => @npoldd2,
			'npoldd3' => @npoldd3,
			'npoldd4' => @npoldd4,
			'nparter' => @nparter,
			'npwmr' => @npwmr,
			'nppath' => @nppath,
			'npnec' => @npnec,
			'nppath2' => @nppath2,
			'nppath3' => @nppath3,
			'nppath4' => @nppath4,
			'nppath5' => @nppath5,
			'nppath6' => @nppath6,
			'nppath7' => @nppath7,
			'nppath8' => @nppath8,
			'nppath9' => @nppath9,
			'nppath10' => @nppath10,
			'nppath11' => @nppath11,
			'nppatho' => @nppatho,
			'nppathox' => @nppathox,
			'nplbod' => @nplbod,
			'npnloss' => @npnloss,
			'nphipscl' => @nphipscl,
			'nptdpa' => @nptdpa,
			'nptdpb' => @nptdpb,
			'nptdpc' => @nptdpc,
			'nptdpd' => @nptdpd,
			'nptdpe' => @nptdpe,
			'npftdtau' => @npftdtau,
			'nppick' => @nppick,
			'npftdt2' => @npftdt2,
			'npcort' => @npcort,
			'npprog' => @npprog,
			'npftdt5' => @npftdt5,
			'npftdt6' => @npftdt6,
			'npftdt7' => @npftdt7,
			'npftdt8' => @npftdt8,
			'npftdt9' => @npftdt9,
			'npftdt10' => @npftdt10,
			'npftdtdp' => @npftdtdp,
			'npalsmnd' => @npalsmnd,
			'npoftd' => @npoftd,
			'npoftd1' => @npoftd1,
			'npoftd2' => @npoftd2,
			'npoftd3' => @npoftd3,
			'npoftd4' => @npoftd4,
			'npoftd5' => @npoftd5,
			'nppdxa' => @nppdxa,
			'nppdxb' => @nppdxb,
			'nppdxc' => @nppdxc,
			'nppdxd' => @nppdxd,
			'nppdxe' => @nppdxe,
			'nppdxf' => @nppdxf,
			'nppdxg' => @nppdxg,
			'nppdxh' => @nppdxh,
			'nppdxi' => @nppdxi,
			'nppdxj' => @nppdxj,
			'nppdxk' => @nppdxk,
			'nppdxl' => @nppdxl,
			'nppdxm' => @nppdxm,
			'nppdxn' => @nppdxn,
			'nppdxo' => @nppdxo,
			'nppdxp' => @nppdxp,
			'nppdxq' => @nppdxq,
			'nppdxr' => @nppdxr,
			'nppdxrx' => @nppdxrx,
			'nppdxs' => @nppdxs,
			'nppdxsx' => @nppdxsx,
			'nppdxt' => @nppdxt,
			'nppdxtx' => @nppdxtx,
			'npbnka' => @npbnka,
			'npbnkb' => @npbnkb,
			'npbnkc' => @npbnkc,
			'npbnkd' => @npbnkd,
			'npbnke' => @npbnke,
			'npbnkf' => @npbnkf,
			'npbnkg' => @npbnkg,
			'npfaut' => @npfaut,
			'npfaut1' => @npfaut1,
			'npfaut2' => @npfaut2,
			'npfaut3' => @npfaut3,
			'npfaut4' => @npfaut4,
			'age_at_death' => @age_at_death,
			# 'npgross' => @npgross,
			# 'npnit' => @npnit,
			# 'npcerad' => @npcerad,
			# 'npadrda' => @npadrda,
			# 'npocrit' => @npocrit,
			# 'npvasc' => @npvasc,
			# 'nplinf' => @nplinf,
			# 'npmicro' => @npmicro,
			# 'nplac' => @nplac,
			# 'nphem' => @nphem,
			# 'npart' => @npart,
			# 'npscl' => @npscl,
			# 'npoang' => @npoang,
			# 'nplewy' => @nplewy,
			# 'npfront' => @npfront,
			# 'nptau' => @nptau,
			# 'npftd' => @npftd,
			# 'npftdno' => @npftdno,
			# 'npftdspc' => @npftdspc,
			# 'npcj' => @npcj,
			# 'npprion' => @npprion,
			# 'npmajor' => @npmajor,
			# 'npmpath2' => @npmpath2,
			# 'npfhspec' => @npfhspec,
			# 'npapoe' => @npapoe,
			# 'npvoth' => @npvoth,
			# 'nplewycs' => @nplewycs,
			# 'npgene' => @npgene,
			# 'nptauhap' => @nptauhap,
			# 'npprnp' => @npprnp,
			# 'npchrom' => @npchrom,
			# 'npbrfrzn' => @npbrfrzn,
			# 'npbrfrm' => @npbrfrm,
			# 'npbparf' => @npbparf,
			# 'npcsfant' => @npcsfant
		}
	end

	def validate_npabanx
		# Despite the way it will look to Excel, the npabanx column should have the name of an 
		# antibody for detecting amyloid. The usual one is called "6E10". When Excel sees that,
		# it thinks that that's a large number (60000000000), rather than a name ("6E10").
		# This should check that we're recording that right.

		#'6E10'.to_i should return 6
		#'60000000000'.to_i should return 60000000000
		#'asdf'.to_i should return 0
		if @npabanx.to_i > 6
			errors.add(:npabanx, "shouldn't actually be a number. This is the name of an antibody.")
		end
	end

	def validate_enumber
		# this is supposed to tell us if the first column on the input spreadsheet matches an enumber in the Panda
		if Enrollment.where(:enumber => @enumber).count == 0
			errors.add(:enumber, "should match an existing enrollment enumber")
		end
	end
end
# CREATE TABLE `cg_neuropathology` (
#   `id` int NOT NULL AUTO_INCREMENT,
#   `enumber` varchar(12) DEFAULT NULL,
#   `reggie_id` varchar(12) DEFAULT NULL,
#   `participant_id` int DEFAULT NULL,
#   `ptid` varchar(12) DEFAULT NULL,
#   `npformmo` varchar(12) DEFAULT NULL,
#   `npformdy` varchar(12) DEFAULT NULL,
#   `npformyr` varchar(12) DEFAULT NULL,
#   `npid` varchar(12) DEFAULT NULL,
#   `npsex` varchar(12) DEFAULT NULL,
#   `npdage` varchar(12) DEFAULT NULL,
#   `npdodmo` varchar(12) DEFAULT NULL,
#   `npdoddy` varchar(12) DEFAULT NULL,
#   `npdodyr` varchar(12) DEFAULT NULL,
#   `nppmih` varchar(12) DEFAULT NULL,
#   `npfix` varchar(12) DEFAULT NULL,
#   `npfixx` varchar(12) DEFAULT NULL,
#   `npwbrwt` varchar(12) DEFAULT NULL,
#   `npwbrf` varchar(12) DEFAULT NULL,
#   `npgrcca` varchar(12) DEFAULT NULL,
#   `npgrla` varchar(12) DEFAULT NULL,
#   `npgrha` varchar(12) DEFAULT NULL,
#   `npgrsnh` varchar(12) DEFAULT NULL,
#   `npgrlch` varchar(12) DEFAULT NULL,
#   `npavas` varchar(12) DEFAULT NULL,
#   `nptan` varchar(12) DEFAULT NULL,
#   `nptanx` varchar(12) DEFAULT NULL,
#   `npaban` varchar(12) DEFAULT NULL,
#   `npabanx` varchar(12) DEFAULT NULL,
#   `npasan` varchar(12) DEFAULT NULL,
#   `npasanx` varchar(12) DEFAULT NULL,
#   `nptdpan` varchar(12) DEFAULT NULL,
#   `nptdpanx` varchar(12) DEFAULT NULL,
#   `nphismb` varchar(12) DEFAULT NULL,
#   `nphisg` varchar(12) DEFAULT NULL,
#   `nphisss` varchar(12) DEFAULT NULL,
#   `nphist` varchar(12) DEFAULT NULL,
#   `nphiso` varchar(12) DEFAULT NULL,
#   `nphisox` varchar(12) DEFAULT NULL,
#   `npthal` varchar(12) DEFAULT NULL,
#   `npbraak` varchar(12) DEFAULT NULL,
#   `npneur` varchar(12) DEFAULT NULL,
#   `npadnc` varchar(12) DEFAULT NULL,
#   `npdiff` varchar(12) DEFAULT NULL,
#   `npamy` varchar(12) DEFAULT NULL,
#   `npinf` varchar(12) DEFAULT NULL,
#   `npinf1a` varchar(12) DEFAULT NULL,
#   `npinf1b` varchar(12) DEFAULT NULL,
#   `npinf1d` varchar(12) DEFAULT NULL,
#   `npinf1f` varchar(12) DEFAULT NULL,
#   `npinf2a` varchar(12) DEFAULT NULL,
#   `npinf2b` varchar(12) DEFAULT NULL,
#   `npinf2d` varchar(12) DEFAULT NULL,
#   `npinf2f` varchar(12) DEFAULT NULL,
#   `npinf3a` varchar(12) DEFAULT NULL,
#   `npinf3b` varchar(12) DEFAULT NULL,
#   `npinf3d` varchar(12) DEFAULT NULL,
#   `npinf3f` varchar(12) DEFAULT NULL,
#   `npinf4a` varchar(12) DEFAULT NULL,
#   `npinf4b` varchar(12) DEFAULT NULL,
#   `npinf4d` varchar(12) DEFAULT NULL,
#   `npinf4f` varchar(12) DEFAULT NULL,
#   `nphemo` varchar(12) DEFAULT NULL,
#   `nphemo1` varchar(12) DEFAULT NULL,
#   `nphemo2` varchar(12) DEFAULT NULL,
#   `nphemo3` varchar(12) DEFAULT NULL,
#   `npold` varchar(12) DEFAULT NULL,
#   `npold1` varchar(12) DEFAULT NULL,
#   `npold2` varchar(12) DEFAULT NULL,
#   `npold3` varchar(12) DEFAULT NULL,
#   `npold4` varchar(12) DEFAULT NULL,
#   `npoldd` varchar(12) DEFAULT NULL,
#   `npoldd1` varchar(12) DEFAULT NULL,
#   `npoldd2` varchar(12) DEFAULT NULL,
#   `npoldd3` varchar(12) DEFAULT NULL,
#   `npoldd4` varchar(12) DEFAULT NULL,
#   `nparter` varchar(12) DEFAULT NULL,
#   `npwmr` varchar(12) DEFAULT NULL,
#   `nppath` varchar(12) DEFAULT NULL,
#   `npnec` varchar(12) DEFAULT NULL,
#   `nppath2` varchar(12) DEFAULT NULL,
#   `nppath3` varchar(12) DEFAULT NULL,
#   `nppath4` varchar(12) DEFAULT NULL,
#   `nppath5` varchar(12) DEFAULT NULL,
#   `nppath6` varchar(12) DEFAULT NULL,
#   `nppath7` varchar(12) DEFAULT NULL,
#   `nppath8` varchar(12) DEFAULT NULL,
#   `nppath9` varchar(12) DEFAULT NULL,
#   `nppath10` varchar(12) DEFAULT NULL,
#   `nppath11` varchar(12) DEFAULT NULL,
#   `nppatho` varchar(12) DEFAULT NULL,
#   `nppathox` varchar(12) DEFAULT NULL,
#   `nplbod` varchar(12) DEFAULT NULL,
#   `npnloss` varchar(12) DEFAULT NULL,
#   `nphipscl` varchar(12) DEFAULT NULL,
#   `nptdpa` varchar(12) DEFAULT NULL,
#   `nptdpb` varchar(12) DEFAULT NULL,
#   `nptdpc` varchar(12) DEFAULT NULL,
#   `nptdpd` varchar(12) DEFAULT NULL,
#   `nptdpe` varchar(12) DEFAULT NULL,
#   `npftdtau` varchar(12) DEFAULT NULL,
#   `nppick` varchar(12) DEFAULT NULL,
#   `npftdt2` varchar(12) DEFAULT NULL,
#   `npcort` varchar(12) DEFAULT NULL,
#   `npprog` varchar(12) DEFAULT NULL,
#   `npftdt5` varchar(12) DEFAULT NULL,
#   `npftdt6` varchar(12) DEFAULT NULL,
#   `npftdt7` varchar(12) DEFAULT NULL,
#   `npftdt8` varchar(12) DEFAULT NULL,
#   `npftdt9` varchar(12) DEFAULT NULL,
#   `npftdt10` varchar(12) DEFAULT NULL,
#   `npftdtdp` varchar(12) DEFAULT NULL,
#   `npalsmnd` varchar(12) DEFAULT NULL,
#   `npoftd` varchar(12) DEFAULT NULL,
#   `npoftd1` varchar(12) DEFAULT NULL,
#   `npoftd2` varchar(12) DEFAULT NULL,
#   `npoftd3` varchar(12) DEFAULT NULL,
#   `npoftd4` varchar(12) DEFAULT NULL,
#   `npoftd5` varchar(12) DEFAULT NULL,
#   `nppdxa` varchar(12) DEFAULT NULL,
#   `nppdxb` varchar(12) DEFAULT NULL,
#   `nppdxc` varchar(12) DEFAULT NULL,
#   `nppdxd` varchar(12) DEFAULT NULL,
#   `nppdxe` varchar(12) DEFAULT NULL,
#   `nppdxf` varchar(12) DEFAULT NULL,
#   `nppdxg` varchar(12) DEFAULT NULL,
#   `nppdxh` varchar(12) DEFAULT NULL,
#   `nppdxi` varchar(12) DEFAULT NULL,
#   `nppdxj` varchar(12) DEFAULT NULL,
#   `nppdxk` varchar(12) DEFAULT NULL,
#   `nppdxl` varchar(12) DEFAULT NULL,
#   `nppdxm` varchar(12) DEFAULT NULL,
#   `nppdxn` varchar(12) DEFAULT NULL,
#   `nppdxo` varchar(12) DEFAULT NULL,
#   `nppdxp` varchar(12) DEFAULT NULL,
#   `nppdxq` varchar(12) DEFAULT NULL,
#   `nppdxr` varchar(12) DEFAULT NULL,
#   `nppdxrx` varchar(100) DEFAULT NULL,
#   `nppdxs` varchar(12) DEFAULT NULL,
#   `nppdxsx` varchar(40) DEFAULT NULL,
#   `nppdxt` varchar(12) DEFAULT NULL,
#   `nppdxtx` varchar(12) DEFAULT NULL,
#   `npbnka` varchar(12) DEFAULT NULL,
#   `npbnkb` varchar(12) DEFAULT NULL,
#   `npbnkc` varchar(12) DEFAULT NULL,
#   `npbnkd` varchar(12) DEFAULT NULL,
#   `npbnke` varchar(12) DEFAULT NULL,
#   `npbnkf` varchar(12) DEFAULT NULL,
#   `npbnkg` varchar(12) DEFAULT NULL,
#   `npfaut` varchar(12) DEFAULT NULL,
#   `npfaut1` varchar(12) DEFAULT NULL,
#   `npfaut2` varchar(12) DEFAULT NULL,
#   `npfaut3` varchar(12) DEFAULT NULL,
#   `npfaut4` varchar(12) DEFAULT NULL,
#   `age_at_death` float DEFAULT NULL,
#   PRIMARY KEY (`id`)
# );

# CREATE TABLE `cg_neuropathology_new` (
#   `id` int NOT NULL AUTO_INCREMENT,
#   `enumber` varchar(12) DEFAULT NULL,
#   `reggie_id` varchar(12) DEFAULT NULL,
#   `participant_id` int DEFAULT NULL,
#   `ptid` varchar(12) DEFAULT NULL,
#   `npformmo` varchar(12) DEFAULT NULL,
#   `npformdy` varchar(12) DEFAULT NULL,
#   `npformyr` varchar(12) DEFAULT NULL,
#   `npid` varchar(12) DEFAULT NULL,
#   `npsex` varchar(12) DEFAULT NULL,
#   `npdage` varchar(12) DEFAULT NULL,
#   `npdodmo` varchar(12) DEFAULT NULL,
#   `npdoddy` varchar(12) DEFAULT NULL,
#   `npdodyr` varchar(12) DEFAULT NULL,
#   `nppmih` varchar(12) DEFAULT NULL,
#   `npfix` varchar(12) DEFAULT NULL,
#   `npfixx` varchar(12) DEFAULT NULL,
#   `npwbrwt` varchar(12) DEFAULT NULL,
#   `npwbrf` varchar(12) DEFAULT NULL,
#   `npgrcca` varchar(12) DEFAULT NULL,
#   `npgrla` varchar(12) DEFAULT NULL,
#   `npgrha` varchar(12) DEFAULT NULL,
#   `npgrsnh` varchar(12) DEFAULT NULL,
#   `npgrlch` varchar(12) DEFAULT NULL,
#   `npavas` varchar(12) DEFAULT NULL,
#   `nptan` varchar(12) DEFAULT NULL,
#   `nptanx` varchar(12) DEFAULT NULL,
#   `npaban` varchar(12) DEFAULT NULL,
#   `npabanx` varchar(12) DEFAULT NULL,
#   `npasan` varchar(12) DEFAULT NULL,
#   `npasanx` varchar(12) DEFAULT NULL,
#   `nptdpan` varchar(12) DEFAULT NULL,
#   `nptdpanx` varchar(12) DEFAULT NULL,
#   `nphismb` varchar(12) DEFAULT NULL,
#   `nphisg` varchar(12) DEFAULT NULL,
#   `nphisss` varchar(12) DEFAULT NULL,
#   `nphist` varchar(12) DEFAULT NULL,
#   `nphiso` varchar(12) DEFAULT NULL,
#   `nphisox` varchar(12) DEFAULT NULL,
#   `npthal` varchar(12) DEFAULT NULL,
#   `npbraak` varchar(12) DEFAULT NULL,
#   `npneur` varchar(12) DEFAULT NULL,
#   `npadnc` varchar(12) DEFAULT NULL,
#   `npdiff` varchar(12) DEFAULT NULL,
#   `npamy` varchar(12) DEFAULT NULL,
#   `npinf` varchar(12) DEFAULT NULL,
#   `npinf1a` varchar(12) DEFAULT NULL,
#   `npinf1b` varchar(12) DEFAULT NULL,
#   `npinf1d` varchar(12) DEFAULT NULL,
#   `npinf1f` varchar(12) DEFAULT NULL,
#   `npinf2a` varchar(12) DEFAULT NULL,
#   `npinf2b` varchar(12) DEFAULT NULL,
#   `npinf2d` varchar(12) DEFAULT NULL,
#   `npinf2f` varchar(12) DEFAULT NULL,
#   `npinf3a` varchar(12) DEFAULT NULL,
#   `npinf3b` varchar(12) DEFAULT NULL,
#   `npinf3d` varchar(12) DEFAULT NULL,
#   `npinf3f` varchar(12) DEFAULT NULL,
#   `npinf4a` varchar(12) DEFAULT NULL,
#   `npinf4b` varchar(12) DEFAULT NULL,
#   `npinf4d` varchar(12) DEFAULT NULL,
#   `npinf4f` varchar(12) DEFAULT NULL,
#   `nphemo` varchar(12) DEFAULT NULL,
#   `nphemo1` varchar(12) DEFAULT NULL,
#   `nphemo2` varchar(12) DEFAULT NULL,
#   `nphemo3` varchar(12) DEFAULT NULL,
#   `npold` varchar(12) DEFAULT NULL,
#   `npold1` varchar(12) DEFAULT NULL,
#   `npold2` varchar(12) DEFAULT NULL,
#   `npold3` varchar(12) DEFAULT NULL,
#   `npold4` varchar(12) DEFAULT NULL,
#   `npoldd` varchar(12) DEFAULT NULL,
#   `npoldd1` varchar(12) DEFAULT NULL,
#   `npoldd2` varchar(12) DEFAULT NULL,
#   `npoldd3` varchar(12) DEFAULT NULL,
#   `npoldd4` varchar(12) DEFAULT NULL,
#   `nparter` varchar(12) DEFAULT NULL,
#   `npwmr` varchar(12) DEFAULT NULL,
#   `nppath` varchar(12) DEFAULT NULL,
#   `npnec` varchar(12) DEFAULT NULL,
#   `nppath2` varchar(12) DEFAULT NULL,
#   `nppath3` varchar(12) DEFAULT NULL,
#   `nppath4` varchar(12) DEFAULT NULL,
#   `nppath5` varchar(12) DEFAULT NULL,
#   `nppath6` varchar(12) DEFAULT NULL,
#   `nppath7` varchar(12) DEFAULT NULL,
#   `nppath8` varchar(12) DEFAULT NULL,
#   `nppath9` varchar(12) DEFAULT NULL,
#   `nppath10` varchar(12) DEFAULT NULL,
#   `nppath11` varchar(12) DEFAULT NULL,
#   `nppatho` varchar(12) DEFAULT NULL,
#   `nppathox` varchar(12) DEFAULT NULL,
#   `nplbod` varchar(12) DEFAULT NULL,
#   `npnloss` varchar(12) DEFAULT NULL,
#   `nphipscl` varchar(12) DEFAULT NULL,
#   `nptdpa` varchar(12) DEFAULT NULL,
#   `nptdpb` varchar(12) DEFAULT NULL,
#   `nptdpc` varchar(12) DEFAULT NULL,
#   `nptdpd` varchar(12) DEFAULT NULL,
#   `nptdpe` varchar(12) DEFAULT NULL,
#   `npftdtau` varchar(12) DEFAULT NULL,
#   `nppick` varchar(12) DEFAULT NULL,
#   `npftdt2` varchar(12) DEFAULT NULL,
#   `npcort` varchar(12) DEFAULT NULL,
#   `npprog` varchar(12) DEFAULT NULL,
#   `npftdt5` varchar(12) DEFAULT NULL,
#   `npftdt6` varchar(12) DEFAULT NULL,
#   `npftdt7` varchar(12) DEFAULT NULL,
#   `npftdt8` varchar(12) DEFAULT NULL,
#   `npftdt9` varchar(12) DEFAULT NULL,
#   `npftdt10` varchar(12) DEFAULT NULL,
#   `npftdtdp` varchar(12) DEFAULT NULL,
#   `npalsmnd` varchar(12) DEFAULT NULL,
#   `npoftd` varchar(12) DEFAULT NULL,
#   `npoftd1` varchar(12) DEFAULT NULL,
#   `npoftd2` varchar(12) DEFAULT NULL,
#   `npoftd3` varchar(12) DEFAULT NULL,
#   `npoftd4` varchar(12) DEFAULT NULL,
#   `npoftd5` varchar(12) DEFAULT NULL,
#   `nppdxa` varchar(12) DEFAULT NULL,
#   `nppdxb` varchar(12) DEFAULT NULL,
#   `nppdxc` varchar(12) DEFAULT NULL,
#   `nppdxd` varchar(12) DEFAULT NULL,
#   `nppdxe` varchar(12) DEFAULT NULL,
#   `nppdxf` varchar(12) DEFAULT NULL,
#   `nppdxg` varchar(12) DEFAULT NULL,
#   `nppdxh` varchar(12) DEFAULT NULL,
#   `nppdxi` varchar(12) DEFAULT NULL,
#   `nppdxj` varchar(12) DEFAULT NULL,
#   `nppdxk` varchar(12) DEFAULT NULL,
#   `nppdxl` varchar(12) DEFAULT NULL,
#   `nppdxm` varchar(12) DEFAULT NULL,
#   `nppdxn` varchar(12) DEFAULT NULL,
#   `nppdxo` varchar(12) DEFAULT NULL,
#   `nppdxp` varchar(12) DEFAULT NULL,
#   `nppdxq` varchar(12) DEFAULT NULL,
#   `nppdxr` varchar(12) DEFAULT NULL,
#   `nppdxrx` varchar(100) DEFAULT NULL,
#   `nppdxs` varchar(12) DEFAULT NULL,
#   `nppdxsx` varchar(40) DEFAULT NULL,
#   `nppdxt` varchar(12) DEFAULT NULL,
#   `nppdxtx` varchar(12) DEFAULT NULL,
#   `npbnka` varchar(12) DEFAULT NULL,
#   `npbnkb` varchar(12) DEFAULT NULL,
#   `npbnkc` varchar(12) DEFAULT NULL,
#   `npbnkd` varchar(12) DEFAULT NULL,
#   `npbnke` varchar(12) DEFAULT NULL,
#   `npbnkf` varchar(12) DEFAULT NULL,
#   `npbnkg` varchar(12) DEFAULT NULL,
#   `npfaut` varchar(12) DEFAULT NULL,
#   `npfaut1` varchar(12) DEFAULT NULL,
#   `npfaut2` varchar(12) DEFAULT NULL,
#   `npfaut3` varchar(12) DEFAULT NULL,
#   `npfaut4` varchar(12) DEFAULT NULL,
#   `age_at_death` float DEFAULT NULL,
#   PRIMARY KEY (`id`)
# );