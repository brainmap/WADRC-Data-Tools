class Lumbarpuncture < ActiveRecord::Base
    belongs_to :appointment
    
    has_many :lumbarpuncture_results,:dependent => :destroy
    accepts_nested_attributes_for :lumbarpuncture_results, :reject_if => :all_blank, :allow_destroy => true
    
    def appointment
        @appointment =Appointment.find(self.appointment_id)
        return @appointment
    end
    
	def summary_hash

    	{
      :Lumbarpuncture_appt_date => appointment.appointment_date,
       :Appt_Coordinator =>@appointment.appointment_coordinator.blank? ? "" : Employee.find(@appointment.appointment_coordinator).name,
      :LP_Initial_needle_insertion_Time => lpstarttime.nil? ? nil : lpstarttime.hour.to_s.rjust(2,'0')+":"+lpstarttime.min.to_s.rjust(2,'0'),
  	  :Fluid_Collection_Start_Time => lpfluidstarttime.nil? ? nil : lpfluidstarttime.hour.to_s.rjust(2,'0')+":"+lpfluidstarttime.min.to_s.rjust(2,'0'),
   	  :LP_final_needle_removal_Time => lpendtime.nil? ? nil : lpendtime.hour.to_s.rjust(2,'0')+":"+lpendtime.min.to_s.rjust(2,'0'),

      :LP_Fast_Completed => completedlpfast == 1 ? "Yes" : "No",
     :LP_Fast_Total_time_range => lpfasttotaltime_range.nil?  ? nil : lpfasttotaltime_range,
     :LP_time_last_intake => lptimelastintake.nil?  ? lptimelastintake_min.nil? ? nil : lptimelastintake.to_s+" hrs : "+lptimelastintake_min.to_s+" mins" :  lptimelastintake.to_s+" hrs : "+lptimelastintake_min.to_s+" mins" ,
     :LP_time_last_intake_unknown => lptimelastintake_unk.to_i == 2 ? "Unknown" : nil,

     :Radiculopathy_complications => lpcomplications_radiculopathy.to_i == 1 ? "Yes" : lpcomplications_radiculopathy.to_i == 0 ? "No" : "Unk",
     :Vasovagal_complications => lpcomplications_vasovagal.to_i == 1 ? "Yes" : lpcomplications_vasovagal.to_i == 0 ? "No" : "Unk",
     :Pain_complications => lpcomplications_pain.to_i == 1 ? "Yes" : lpcomplications_pain.to_i == 0 ? "No" : "Unk",
     :Headache_complications => lpcomplications_headache.to_i == 1 ? "Yes" : lpcomplications_headache.to_i == 0 ? "No" : "Unk",
     :Other_complications => lpcomplications_other.to_i == 1 ? "Yes" : lpcomplications_other.to_i == 0 ? "No" : "Unk",
     :Other_comlicatoins_description => lpcomplications_other_specify,

      :CSF_Amount_collected =>  lpamountcollected.nil? ? nil : lpamountcollected.to_s+" ml"  ,
      :CSF_Amount_stored => lpinitialamountstored.nil? ? nil : lpinitialamountstored.to_s+" ml"  ,
      :Amount_of_lidocaine_administered => lpamountoflidocaine.nil? ? nil : lpamountoflidocaine.to_s+" ml"  ,


     :Needle_gauge => lpneedle_gauge,
     :Needle_length => lpneedle_length,
     :Needle_type => lpneedletype,

     :Sitting_position? => lpposition_sitting.to_i == 1 ? "Yes" : "No" ,
     :Decubitus_position? => lpposition_decubitus.to_i == 1 ? "Yes" : "No" ,

     :Extracted_by_gravity? => lpmethod_gravity,
     :Amount_extracted_by_gravity => lpmethod_gravity_collected.nil? ? nil : lpmethod_gravity_collected.to_s+" ml"  ,
     :Extracted_by_aspiration? => lpmethod_aspiration,
     :Amount_extracted_by_aspiration => lpmethod_aspiration_collected.nil? ? nil : lpmethod_aspiration_collected.to_s+" ml"  ,

    :Significant_post_LP_Headache => followupheadache,
    :Significant_post_LP_Headache_Date_Resolved => followupheadache.nil? ? nil : followupheadache =="yes" ? lpheadache_dateresolved.nil? ? nil : lpheadache_dateresolved.strftime("%Y-%m-%d") : nil,
    :Significant_post_LP_Headache_severity => followupheadache.nil? ? nil : followupheadache == "yes" ? lpheadache_severity : nil,

    :Significant_low_back_pain => lplowbackpain,
    :Significant_low_back_pain_Date_Resolved => lplowbackpain.nil? ? nil : lplowbackpain =="yes" ? lplowbackpain_dateresolved.nil? ? nil : lplowbackpain_dateresolved.strftime("%Y-%m-%d") : nil,
    :Significant_low_back_pain_severity => lplowbackpain.nil? ? nil : lplowbackpain == "yes" ? lplowbackpain_severity : nil,
    :Other_side_effects => lpothersideeffects,
    :Other_side_effects_Date_Resolved => lpothersideeffects.nil? ? nil : lpothersideeffects =="yes" ? lpothersideeffects_dateresolved.nil? ? nil : lpothersideeffects_dateresolved.strftime("%Y-%m-%d") : nil,
    :Other_side_effects_severity => lpothersideeffects.nil? ? nil : lpothersideeffects == "yes" ? lpothersideeffects_severity : nil,

    :CSF_Nucleated_Cell_Count => lpcsfnucleatedcellcount.nil? ? nil : lpcsfnucleatedcellcount.to_s,
    :CSF_Red_Cell_Count => lpcsfredcellcount.nil? ? nil : lpcsfredcellcount.to_s,

      :MD_for_Lumbarpuncture => lp_exam_md_id.nil? ? nil : Employee.find(lp_exam_md_id).name,

      :LP_Successful => lpsuccess == 1 ? "Yes" : lpsuccess == 0 ? "No" : "Unknown",

    :If_unsuccessful_LP_Unable_to_access_CSF => lpsuccess.to_i == 1 ? nil : lpcsfunsuccessful_noaccess.to_i == 1 ? "Yes" : nil,
    :If_unsuccessful_Participant_Pain_discomfort => lpsuccess.to_i == 1 ? nil : lpcsfunsuccessful_pain.to_i == 1 ? "Yes" : nil,
    :If_unsuccessful_Participant_vasoval => lpsuccess.to_i == 1 ? nil : lpcsfunsuccessful_vasovagal.to_i == 1 ? "Yes" : nil,
    :If_unsuccessful_other => lpsuccess.to_i == 0 ? lpcsfunsuccessful_other.to_i == 1  ? lpcsfunsuccessful_other_specify.nil? ? nil : lpcsfunsuccessful_other_specify : nil : nil,

      # :LP_Abnormality_Found =>  lpabnormality == 1 ? "Yes" : "No" ,
      :Participant => @participant.nil? ? nil : link_to('view participant', @participant),
      # :Needle_Size => needlesize,
      # :Needle_Type => lpneedletype.nil? ? nil : lpneedletype == "Other" ? lpneedletype_other : lpneedletype,
      # :LP_Position => lpposition.nil? ? nil : lpposition,
      # :LP_Method => lpmethod.nil? ? nil : lpmethod,

    :LP_data_entered_by => lp_data_entered_by.blank? ? "" : User.find(lp_data_entered_by).username_name,
    :LP_Data_entry_date => lp_data_entered_date.nil? ? nil : lp_data_entered_date.strftime("%Y-%m-%d"),
      :LP_data_qced_by => lp_data_qced_by.blank? ? "" : User.find(lp_data_qced_by).username_name,
    :LP_Data_qced_date => lp_data_qced_date.nil? ? nil : lp_data_qced_date.strftime("%Y-%m-%d")
     }
    end
    
end
