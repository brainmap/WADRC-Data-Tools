class RedcapE4V6Form

	# 2021-07-02 wbbevis -- this form is for importing ADRC LPs in E4 v6 format from REDcap


	attr_accessor :lumbarpuncture_fields, :vitals_fields, :appointment_fields
	attr_accessor :enumber

	def self.from_csv (row)

		out = RedcapE4V6Form.new

		out.lumbarpuncture_fields = {}
		out.vitals_fields = {}
		out.appointment_fields = {}

		out.enumber = row["ptid"] 
		out.appointment_fields["appointment_date"] = Date.strptime(row["lpdt_e4_v6"], "%Y-%m-%d")
		# "formver_e4", 
		out.lumbarpuncture_fields["lpstarttime_time"] = row["insert_e4_v6"]
		out.lumbarpuncture_fields["lpfluidstarttime_time"] = row["flow_e4_v6"]
		out.lumbarpuncture_fields["lpendtime_time"] = row["remov_e4_v6"]
		out.vitals_fields["bp_systol"] = row["bpsys_e4_v6"].to_f
		out.vitals_fields["bp_diastol"] = row["bpdias_e4_v6"].to_f
		out.vitals_fields["pulse"] = row["pulse_e4_v6"].to_i

		out.lumbarpuncture_fields["completedlpfast"] = case row["lpfast_e4_v6"].to_i
		when 1
			'yes'
		when 0
			'no'
		else
			nil
		end

		# here, if intake_e4_v6 < "2020-01-20 07:00", then we can just
		#  leave these null
		datetime_of_last_intake = Date.strptime(row["intake_e4_v6"],"%Y-%m-%d %H:%M")
		if datetime_of_last_intake >= Date.new(2020,1,20,7)

			fast_time_parts = row["intake_e4_v6"].split(" ")
			hour_minute = fast_time_parts[1].split(":")

			out.lumbarpuncture_fields["lptimelastintake"] = hour_minute[0]
			out.lumbarpuncture_fields["lptimelastintake_min"] = hour_minute[1]
		else
			out.lumbarpuncture_fields["lptimelastintake"] = nil
			out.lumbarpuncture_fields["lptimelastintake_min"] = nil
		end

		# choices[""] = "adv_effect_e4_v6"
		out.lumbarpuncture_fields["lpcomplications_radiculopathy"] = row["effects_e4_v6___1"].to_i
		out.lumbarpuncture_fields["lpcomplications_vasovagal"] = row["effects_e4_v6___2"].to_i
		out.lumbarpuncture_fields["lpcomplications_pain"] = row["effects_e4_v6___3"].to_i
		out.lumbarpuncture_fields["lpcomplications_headache"] = row["effects_e4_v6___4"].to_i
		out.lumbarpuncture_fields["lpcomplications_other"] = row["effects_e4_v6___5"].to_i
		out.lumbarpuncture_fields["lpcomplications_other_specify"] = row["effects_other_e4_v6"].to_i
		out.appointment_fields["comment"] = row["effects_comment_e4_v6"]
		
		out.lumbarpuncture_fields["lpamountoflidocaine"] = row["lidocaine_e4_v6"].to_f
		out.lumbarpuncture_fields["lpneedle_gauge"] = row["ndlga_e4_v6"].to_i
		out.lumbarpuncture_fields["lpneedle_length"] = row["ndllngth_e4_v6"]

		out.lumbarpuncture_fields["lpneedletype"] = case row["ndletype_e4_v6"].to_i
		when 1
			'Sprotte'
		when 2
			'Other'
		else
			'?'
		end

		# choices["lumbarpunctures.lpneedletype"] = row["ndlspec_e4_v6"]
		# "needle2_e4_v6" 
		# "ndlga2_e4_v6" 
		# "needle2_len_e4_v6" 
		# "needle2_type_e4_v6"
		# "needle2_other_e4_v6"
		out.lumbarpuncture_fields["lpposition_sitting"] = case row["lpsit_e4_v6"].to_i
		when 1
			'yes'
		when 0
			'no'
		else
			nil
		end


		out.lumbarpuncture_fields["lpposition_decubitus"] = case row["lpdecub_e4_v6"].to_i
		when 1
			'yes'
		when 0
			'no'
		else
			nil
		end


		out.lumbarpuncture_fields["lpmethod_gravity"] = case row["gravity_e4_v6"].to_i
		when 1
			'yes'
		when 0
			'no'
		else
			nil
		end

		out.lumbarpuncture_fields["lpmethod_gravity_collected"] = row["gravity_amt_e4_v6"].to_f

		out.lumbarpuncture_fields["lpmethod_aspiration"] = case row["aspiration_e4_v6"].to_i
		when 1
			'yes'
		when 0
			'no'
		else
			nil
		end

		out.lumbarpuncture_fields["lpmethod_aspiration_collected"] = row["aspiration_amt_e4_v6"].to_f

		out.lumbarpuncture_fields["lpamountcollected"] = row["lpamt_e4_v6"].to_f
		out.lumbarpuncture_fields["lpinitialamountstored"] = row["lpamt_2_e4_v6"].to_f

		out.lumbarpuncture_fields["followupheadache"] = case row["hdache_e4_v6"].to_i
		when 1
			'yes'
		when 0
			'no'
		else
			nil
		end

		if row["hdacherslv_e4_v6"] != ''
			out.lumbarpuncture_fields["lpheadache_dateresolved"] = Date.strptime(row["hdacherslv_e4_v6"],"%Y-%m-%d")
		else
			out.lumbarpuncture_fields["lpheadache_dateresolved"] = nil
		end
		
		out.lumbarpuncture_fields["lpheadache_severity"] = case row["headsev_e4_v6"].to_i
		when 1
			'mild (0-3/10)'
		when 2
			'moderate (4-6/10)'
		when 3
			'severe (7-10/10)'
		else
			''
		end

		out.lumbarpuncture_fields["lpheadache_note"] = row["headnotes_e4_v6"]


		out.lumbarpuncture_fields["lplowbackpain"] = case row["lwbkpain_e4_v6"].to_i
		when 1
			'yes'
		when 0
			'no'
		else
			nil
		end

		if row["lwbkpainrslv_e4_v6"] != ''
			out.lumbarpuncture_fields["lplowbackpain_dateresolved"] = Date.strptime(row["lwbkpainrslv_e4_v6"],"%Y-%m-%d")
		else
			out.lumbarpuncture_fields["lplowbackpain_dateresolved"] = nil
		end

		out.lumbarpuncture_fields["lplowbackpain_severity"] = case row["lwbksev_e4_v6"].to_i
		when 1
			'mild (0-3/10)'
		when 2
			'moderate (4-6/10)'
		when 3
			'severe (7-10/10)'
		else
			''
		end
		out.lumbarpuncture_fields["lplowbackpain_note"] = row["lwbknotes_e4_v6"]

		out.lumbarpuncture_fields["lpothersideeffects"] = case row["othreff_e4_v6"].to_i
		when 1
			'yes'
		when 0
			'no'
		else
			nil
		end

		if row["othreff_res_e4_v6"] != ''
			out.lumbarpuncture_fields["lpothersideeffects_dateresolved"] = Date.strptime(row["othreff_res_e4_v6"],"%Y-%m-%d")
		else
			out.lumbarpuncture_fields["lpothersideeffects_dateresolved"] = nil
		end

		out.lumbarpuncture_fields["lpothersideeffects_severity"] = case row["othreff_sev_e4_v6"]
		when 1
			'mild (0-3/10)'
		when 2
			'moderate (4-6/10)'
		when 3
			'severe (7-10/10)'
		else
			''
		end
		out.lumbarpuncture_fields["lpothersideeffects_note"] = row["othreff_notes_e4_v6"]

		out.lumbarpuncture_fields["lpfollownote"] = row["lprmrks_e4_v6"]
		out.lumbarpuncture_fields["lpcsfnucleatedcellcount"] = row["ncelcnt_e4_v6"].to_i
		out.lumbarpuncture_fields["lpcsfredcellcount"] = row["rcelcnt_e4_v6"].to_i
		out.lumbarpuncture_fields["lpcsfcellcount_note"] = row["celcntrmrk_e4_v6"]
		out.lumbarpuncture_fields["lpsuccess"] = row["lpsuccess_e4_v6"].to_i
		out.lumbarpuncture_fields["lpcsfunsuccessful_noaccess"] = row["reason_1a_e4_v6"].to_i
		out.lumbarpuncture_fields["lpcsfunsuccessful_pain"] = row["reason_2a_e4_v6"].to_i
		out.lumbarpuncture_fields["lpcsfunsuccessful_vasovagal"] = row["reason_3a_e4_v6"].to_i
		out.lumbarpuncture_fields["lpcsfunsuccessful_other"] = row["reason_4a_e4_v6"].to_i
		out.lumbarpuncture_fields["lpcsfunsuccessful_other_specify"] = row["othrsn_e4_v6"]
		out.lumbarpuncture_fields["preanalytic_protocol"] = row["preanalytic"]
		

		out.lumbarpuncture_fields["lp_exam_md_id"] = case row["lpmd_e4_v6"]
		when 1
			87 # ["Aleshia Cole ", 87], 1	Aleshia Cole, NP
		when 2
			162 #["Camille Conway, NP ", 162] 2	Camille Conway, NP
		when 3
			141 #["Cynthia Carlson, NP ", 141], 3	Cynthia Carlson, NP
		when 4
			163 #["DaRae Coughlin, NP ", 163],4	DaRae Coughlin, NP
		when 5
			53 #["Dr. Cindy Carlsson, MD ", 53] 5	Cynthia Carlsson, MD
		when 7
			116 #["Nathaniel Chin ", 116] 7	Nathaniel Chin
		else
			nil
		end

		# "lpmd_other_e4_v6"

		# "wadrc_e4_v6_lp_complete"

		return out
	end

	def create_lp_appointment(vgroup)

		ppt = Participant.find(vgroup.enrollments.map(&:participant_id).uniq.compact.first)

		new_appt = Appointment.new(@appointment_fields.merge({:vgroup_id => vgroup.id, :appointment_type => 'lumbar_puncture'}))
		new_appt.age_at_appointment = ((new_appt.appointment_date - ppt.dob)/365.25).round(2)
		new_appt.save

		new_lp = Lumbarpuncture.new(@lumbarpuncture_fields.merge({:appointment_id => new_appt.id}))
		new_lp.save

		new_vital = Vital.new(@vitals_fields.merge({:appointment_id => new_appt.id}))
		new_vital.save

	end

end

