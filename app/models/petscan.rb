class Petscan < ActiveRecord::Base
  belongs_to :appointment
  
  default_scope :order => 'appointment_id DESC'
  
  def appointment
      @appointment =Appointment.find(self.appointment_id)
      return @appointment
  end
  
  def get_pet_file(p_sp_id, p_tracer_id, p_vgroup_id)
    # ???? '1_asthana.adrc-clinical-core.visit1'=>'', '2_bendlin.tami.visit1'=>'', '1_bendlin.wmad.visit1'=>'','1_bendlin.mets.visit1'=> '',    '2_bendlin.mets.visit1'=> ''
    # 2_ries.mosaic.visit1    3_ries.mosaic.visit1
    # tracer 1=pib, 2=fdg, 3=way, 4=015
    v_base_path = Shared.get_base_path()
    v_pet_target_hash ={'1_johnson.pipr.visit1'=>'johnson.pipr.visit1/pet','2_johnson.predict.visit1'=>'johnson.predict.visit1/pet/FDG-visit1',
         '1_johnson.predict.visit1'=>'johnson.predict.visit1/pet/PIB-visit1','2_johnson.predict.visit2'=>'johnson.predict.visit2/pet/FDG',
         '1_johnson.predict.visit2'=>'johnson.predict.visit2/pet/PIB','2_johnson.rhesus.visit2'=>'johnson.rhesus.visit2/pet/FDG',
         '2_ries.mosaic.visit1'=>'ries.mosaic.visit1/pet/FDG',    '3_ries.mosaic.visit1'=>'ries.mosaic.visit1/pet/WAY',
         '2_johnson.rhesus.visit2'=>'johnson.rhesus.visit2/pet/FDG' }
    v_sp = ScanProcedure.find(p_sp_id)
    v_key = p_tracer_id.to_s+"_"+v_sp.codename
    v_file_name = ""
    if !v_pet_target_hash[v_key].blank?
        v_path = v_base_path+"/raw/"+v_pet_target_hash[v_key]+"/"
        # check for file with enum 
        vgroup = Vgroup.find(p_vgroup_id)
        (vgroup.enrollments).each do |e|
          if !Dir.glob(v_path+e.enumber+"*").empty?
            v_cnt = 0
            Dir.glob(v_path+e.enumber+"*").each do |f|
               v_file_name = f.gsub(v_path,"")
               v_cnt = v_cnt + 1
            end   
            if v_cnt > 1
              v_file_name = ""
            end      
          end
        end
    else
        puts "AAAAAAAAA "+v_key+"   no path for sp in hash"
    end
    return v_file_name
  end
  
  def get_pet_path(p_sp_id, p_file_name, p_tracer_id)
    # ???? '1_asthana.adrc-clinical-core.visit1'=>'', '2_bendlin.tami.visit1'=>'', '1_bendlin.wmad.visit1'=>'','1_bendlin.mets.visit1'=> '',    '2_bendlin.mets.visit1'=> ''
    # 2_ries.mosaic.visit1    3_ries.mosaic.visit1
    # tracer 1=pib, 2=fdg, 3=way, 4=015
    v_base_path = Shared.get_base_path()
    v_pet_target_hash ={'1_johnson.pipr.visit1'=>'johnson.pipr.visit1/pet','2_johnson.predict.visit1'=>'johnson.predict.visit1/pet/FDG-visit1',
         '1_johnson.predict.visit1'=>'johnson.predict.visit1/pet/PIB-visit1','2_johnson.predict.visit2'=>'johnson.predict.visit2/pet/FDG',
         '1_johnson.predict.visit2'=>'johnson.predict.visit2/pet/PIB','2_johnson.rhesus.visit2'=>'johnson.rhesus.visit2/pet/FDG',
         '2_ries.mosaic.visit1'=>'ries.mosaic.visit1/pet/FDG',    '3_ries.mosaic.visit1'=>'ries.mosaic.visit1/pet/WAY',
         '2_johnson.rhesus.visit2'=>'johnson.rhesus.visit2/pet/FDG' }
    v_sp = ScanProcedure.find(p_sp_id)
    v_key = p_tracer_id.to_s+"_"+v_sp.codename
    v_path = ""
    if !v_pet_target_hash[v_key].blank?
        v_path = v_base_path+"/raw/"+v_pet_target_hash[v_key]+"/"+p_file_name
    else
        puts "AAAAAAAAA "+v_key+"   "+p_file_name
    end
    if File.exists?(v_path)
      return v_path
    else
      return ""
    end
  end
  
  def petscan_appointment_date
      @appointment =Appointment.find(self.appointment_id)
      return @appointment.appointment_date
  end
  # how to order by the appointment_date????? 
  # in the db its regular time, but ror converts it to GMT?  --- actually utc in the database -- add 6 or 5 hours to the access db time during import to msql
#  def injecttiontime_utc
#    self.injecttiontime.try(:utc)
#  end
  
#  def scanstarttime_utc
#    self.scanstarttime.try(:utc)
#  end
end
