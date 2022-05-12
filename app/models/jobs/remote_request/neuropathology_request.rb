class Jobs::RemoteRequest::NeuropathologyRequest < Jobs::RemoteRequest::RemoteRequestBase

	# This is a service class that requests the latest radiology reads from the radiology site, then
	# records them in the panda. Now that our rad reads are coming as JSONs, this is a lot easier.
	attr_accessor :response, :base_args, :records

	def self.default_params
	  	params = { :schedule_name => 'Neuropathology Request', 
	  				:run_by_user => 'panda_user',
	  				:adrc_token => Rails.application.config.adrc_neuropathology_token,
	  				:wrap_token => Rails.application.config.wrap_neuropathology_token,
	  				:neuropathology_table => 'cg_neuropathology'
	  			}
        params.default = ''
        params
    end

	def login(params)
		#looks like we can do this with just one step

	end

	def selection(params)

	end


	def record(params)

		sql = "truncate #{params[:neuropathology_table]}_new"
		@connection.execute(sql)

		@base_args = {
			:token => params[:adrc_token],
			:content => 'record',
			:format => 'json',
			:type => 'flat',
			:rawOrLabel => 'raw',
			:rawOrLabelHeaders => 'raw',
			:exportCheckboxLabel => 'false',
			:exportSurveyFields => 'false',
			:exportDataAccessGroups => 'false',
			:returnFormat => 'json'
		}

		#get the subjects, along with which forms they've completed
		ardc_options = @base_args.merge({'fields[0]' => 'nacc_neuropathology_data_form_v10_complete',
									'fields[1]' => 'ptid'
								})

		http = HTTPClient.new
		@response = http.post("https://redcap.medicine.wisc.edu/api/",ardc_options)

		@records = JSON.parse(@response.body)
		self.log << {'message' => "Response was #{@response.code}"}

		self.log << {'message' => "ADRC -- Starting to record the neuropath data."}
		v10_subjects = @records.select{|res| res['nacc_neuropathology_data_form_v10_complete'] == "2"}

		v10_subjects.each do |subj|

			options = @base_args.merge({'records[0]' => subj['ptid']})
			v10_response = http.post("https://redcap.medicine.wisc.edu/api/",options)

			#we should validate this JSON
			v10_form = NeuropathologyV10Form.from_json(JSON.parse(v10_response.body)[0])

			if v10_form.valid?

				sql = v10_form.to_sql_insert("#{params[:neuropathology_table]}_new")

				result = @connection.execute(sql)

			end
		end

		#then the same for the WRAP ppts
		wrap_options = @base_args.merge({:token => params[:wrap_token],
									'fields[0]' => 'wrap_neuropathology_data_form_v10_complete',
									'fields[1]' => 'ptid'
								})

		http = HTTPClient.new
		@response = http.post("https://redcap.medicine.wisc.edu/api/",wrap_options)

		@records += JSON.parse(@response.body)
		@log.info(@params[:schedule_name]) { "Response was #{@response.code}"}

		@log.info(@params[:schedule_name]) { "WRAP -- Starting to record the neuropath data."}
		wrap_v10_subjects = @records.select{|res| res['wrap_neuropathology_data_form_v10_complete'] == "2"}

		wrap_v10_subjects.each do |subj|

			options = @base_args.merge({:token => params[:wrap_token],'records[0]' => subj['ptid']})
			v10_response = http.post("https://redcap.medicine.wisc.edu/api/",options)

			#we should validate this JSON
			v10_form = NeuropathologyV10Form.from_json(JSON.parse(v10_response.body)[0])

			if v10_form.valid?

				sql = v10_form.to_sql_insert("#{params[:neuropathology_table]}_new")

				result = @connection.execute(sql)

			end
		end

		# there are 7 cases from ADRC that had an old version of the form. They're not going to be
		# changed, and it's prohibitive to do a mapping from v9 to v10, so I've got them just saved.

		sql = "insert into cg_neuropathology_new (enumber,reggie_id,participant_id,ptid,npformmo,npformdy,npformyr,npid,npsex,npdage,npdodmo,npdoddy,npdodyr,nppmih,npfix,npfixx,npwbrwt,npwbrf,npgrcca,npgrla,npgrha,npgrsnh,npgrlch,npavas,nptan,nptanx,npaban,npabanx,npasan,npasanx,nptdpan,nptdpanx,nphismb,nphisg,nphisss,nphist,nphiso,nphisox,npthal,npbraak,npneur,npadnc,npdiff,npamy,npinf,npinf1a,npinf1b,npinf1d,npinf1f,npinf2a,npinf2b,npinf2d,npinf2f,npinf3a,npinf3b,npinf3d,npinf3f,npinf4a,npinf4b,npinf4d,npinf4f,nphemo,nphemo1,nphemo2,nphemo3,npold,npold1,npold2,npold3,npold4,npoldd,npoldd1,npoldd2,npoldd3,npoldd4,nparter,npwmr,nppath,npnec,nppath2,nppath3,nppath4,nppath5,nppath6,nppath7,nppath8,nppath9,nppath10,nppath11,nppatho,nppathox,nplbod,npnloss,nphipscl,nptdpa,nptdpb,nptdpc,nptdpd,nptdpe,npftdtau,nppick,npftdt2,npcort,npprog,npftdt5,npftdt6,npftdt7,npftdt8,npftdt9,npftdt10,npftdtdp,npalsmnd,npoftd,npoftd1,npoftd2,npoftd3,npoftd4,npoftd5,nppdxa,nppdxb,nppdxc,nppdxd,nppdxe,nppdxf,nppdxg,nppdxh,nppdxi,nppdxj,nppdxk,nppdxl,nppdxm,nppdxn,nppdxo,nppdxp,nppdxq,nppdxr,nppdxrx,nppdxs,nppdxsx,nppdxt,nppdxtx,npbnka,npbnkb,npbnkc,npbnkd,npbnke,npbnkf,npbnkg,npfaut,npfaut1,npfaut2,npfaut3,npfaut4,age_at_death) values 
('adrc00010','3071','3729','adrc00010','5','2','2013',NULL,'1','88','3','2','2013','.','.',NULL,'.','.','.','.','.','.','.','2','.',NULL,'.','6E10','.',NULL,'.',NULL,'.','.','.','.','.',NULL,'.','5','1','.','2','1','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','3','.','.','2','.','.','.','.','.','.','.','.','.','.','.',NULL,'.','.','.','.','.','.','.','.','.','2','.','2','2','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.',NULL,'.',NULL,'.',NULL,'.','.','.','.','.','.','.','.',NULL,NULL,NULL,NULL,88.78),
('adrc00017','2316','2922','adrc00017','12','21','2010',NULL,'1','73','10','11','2010','.','.',NULL,'.','.','.','.','.','.','.','2','.',NULL,'.','6E10','.',NULL,'.',NULL,'.','.','.','.','.',NULL,'.','4','2','.','3','2','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','2','.','.','2','.','.','.','.','.','.','.','.','.','.','.',NULL,'.','.','.','.','.','.','.','.','.','2','.','2','2','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.',NULL,'.',NULL,'.',NULL,'.','.','.','.','.','.','.','.',NULL,NULL,NULL,NULL,73.62),
('adrc00049','3073','2959','adrc00049','10','22','2012',NULL,'1','68','7','8','2012','.','.',NULL,'.','.','.','.','.','.','.','2','.',NULL,'.','6E10','.',NULL,'.',NULL,'.','.','.','.','.',NULL,'.','5','2','.','1','4','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','2','.','.','1','.','.','.','.','.','.','.','.','.','.','.',NULL,'.','.','.','.','.','.','.','.','.','2','.','2','2','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.',NULL,'.',NULL,'.',NULL,'.','.','.','.','.','.','.','.',NULL,NULL,NULL,NULL,68.1),
('adrc00055','3017','3734','adrc00055','10','22','2012',NULL,'2','92','5','25','2012','.','.',NULL,'.','.','.','.','.','.','.','2','.',NULL,'.','6E10','.',NULL,'.',NULL,'.','.','.','.','.',NULL,'.','2','4','.','4','1','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','2','.','.','2','.','.','.','.','.','.','.','.','.','.','.',NULL,'.','.','.','.','.','.','.','.','.','2','.','2','2','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.',NULL,'.',NULL,'.',NULL,'.','.','.','.','.','.','.','.',NULL,NULL,NULL,NULL,92.07),
('adrc00076','2780','2970','adrc00076','5','1','2012',NULL,'1','86','3','18','2012','.','.',NULL,'.','.','.','.','.','.','.','2','.',NULL,'.','6E10','.',NULL,'.',NULL,'.','.','.','.','.',NULL,'.','6','1','.','1','2','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','2','.','.','2','.','.','.','.','.','.','.','.','.','.','.',NULL,'.','.','.','.','.','.','.','.','.','2','.','2','2','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.',NULL,'.',NULL,'.',NULL,'.','.','.','.','.','.','.','.',NULL,NULL,NULL,NULL,86.03),
('adrc00080','3510','2981','adrc00080','9','5','2013',NULL,'2','85','5','31','2013','.','.',NULL,'.','.','.','.','.','.','.','4','.',NULL,'.','6E10','.',NULL,'.',NULL,'.','.','.','.','.',NULL,'.','2','2','.','1','4','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','3','.','.','2','.','.','.','.','.','.','.','.','.','.','.',NULL,'.','.','.','.','.','.','.','.','.','2','.','2','2','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.',NULL,'.',NULL,'.',NULL,'.','.','.','.','.','.','.','.',NULL,NULL,NULL,NULL,85.13),
('adrc00251','5749','2768','adrc00251','9','5','2013',NULL,'2','87','5','23','2013','.','.',NULL,'.','.','.','.','.','.','.','3','.',NULL,'.','6E10','.',NULL,'.',NULL,'.','.','.','.','.',NULL,'.','2','2','.','1','1','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','3','.','.','1','.','.','.','.','.','.','.','.','.','.','.',NULL,'.','.','.','.','.','.','.','.','.','2','.','2','2','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.','.',NULL,'.',NULL,'.',NULL,'.','.','.','.','.','.','.','.',NULL,NULL,NULL,NULL,87.93);"
		result = @connection.execute(sql)

		@log.info(@params[:schedule_name]) { "Storing is complete!"}
	end


	def rotate_tables(params)
		sql = "truncate table #{params[:neuropathology_table]}"
		@connection.execute(sql)
		sql = "insert into #{params[:neuropathology_table]} select * from #{params[:neuropathology_table]}_new"
		@connection.execute(sql)
	end
end