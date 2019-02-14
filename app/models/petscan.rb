require 'tmpdir'
require 'dicom'
class Petscan < ActiveRecord::Base
  belongs_to :appointment 
  has_many :petfiles,:class_name =>"Petfile", :dependent => :destroy  
  # not sure if will cause problems -- subjectid -visit1, visit2
  # need to also toss in scan procedure?
  #validates_uniqueness_of :file_name, :case_sensitive => false, :unless => Proc.new {|petscan| petscan.file_name.blank?}
  
  
  #default_scope :order => 'appointment_id DESC'  
   default_scope { order(appointment_id: :desc) }  
  
  def appointment
      @appointment =Appointment.find(self.appointment_id)
      return @appointment
  end
  # ONLY ONE FILE
  def get_pet_file(p_sp_id, p_tracer_id, p_vgroup_id)
    # ???? '1_asthana.adrc-clinical-core.visit1'=>'', '2_bendlin.tami.visit1'=>'', '1_bendlin.wmad.visit1'=>'','1_bendlin.mets.visit1'=> '',    '2_bendlin.mets.visit1'=> ''
    # 2_ries.mosaic.visit1    3_ries.mosaic.visit1
    # tracer 1=pib, 2=fdg, 3=way, 4=015
    v_base_path = Shared.get_base_path()
    #v_pet_target_hash ={'1_johnson.pipr.visit1'=>'johnson.pipr.visit1/pet','2_johnson.predict.visit1'=>'johnson.predict.visit1/pet/FDG-visit1',
    #     '1_johnson.predict.visit1'=>'johnson.predict.visit1/pet/PIB-visit1','2_johnson.predict.visit2'=>'johnson.predict.visit2/pet/FDG',
    #     '1_johnson.predict.visit2'=>'johnson.predict.visit2/pet/PIB','2_johnson.rhesus.visit2'=>'johnson.rhesus.visit2/pet/FDG',
    #     '2_ries.mosaic.visit1'=>'ries.mosaic.visit1/pet/FDG',    '3_ries.mosaic.visit1'=>'ries.mosaic.visit1/pet/WAY',
    #     '2_johnson.rhesus.visit2'=>'johnson.rhesus.visit2/pet/FDG',
    #     '5_bendlin.pbr28.visit1'=>'bendlin.pbr28.visit1/pet/PBR',
    #      '2_ADNI-2'=>'ADNI-2/pet/FDG', 
    #       '6_ADNI-2'=>'ADNI-2/pet/AV45'}
    v_sp = ScanProcedure.find(p_sp_id)
    v_pet_target_path = ""
    if !v_sp.petscan_tracer_path.blank?
      v_tracer_path_array = v_sp.petscan_tracer_path.split("|")
      v_tracer_path_array.each do |tr|
        v_tracer_path = tr.split(":")
        if v_tracer_path[0] == p_tracer_id.to_s
            v_pet_target_path = v_tracer_path[1]
        end
      end
    end
    #v_key = p_tracer_id.to_s+"_"+v_sp.codename
    v_file_name = ""
 puts "zzzzz v_file_name="+v_file_name
    if !v_pet_target_path.blank?
        v_path = v_base_path+"/raw/"+v_pet_target_path+"/"
        # check for file with enum 
        vgroup = Vgroup.find(p_vgroup_id)
        # first checking for path including enumber dir
        (vgroup.enrollments).each do |e|    
          if !Dir.glob(v_path+e.enumber+"/"+e.enumber+"*").empty?   or !Dir.glob(v_path+e.enumber+"/"+"*"+e.enumber[1..-1]+"*.img").empty?
            v_cnt = 0
            Dir.glob(v_path+e.enumber+"/"+e.enumber+"*").each do |f|
               # need to exclude directories - so not pick up the dicom dirs
               if File.file?(f)
                 v_file_name = f.gsub(v_path+e.enumber+"/","")
                 v_cnt = v_cnt + 1
               end
            end   
            if v_cnt < 1
              Dir.glob(v_path+e.enumber+"/"+"*"+e.enumber[1..-1]+"*.img").each do |f|
                 v_file_name = f.gsub(v_path+e.enumber+"/","")
                 v_cnt = v_cnt + 1
              end
            end
            if v_cnt > 1
              v_file_name = ""
            end 
          elsif !Dir.glob(v_path+e.enumber+"/"+e.enumber.upcase+"*").empty?   or !Dir.glob(v_path+e.enumber+"/"+"*"+e.enumber[1..-1].upcase+"*.img").empty?
            v_cnt = 0
            Dir.glob(v_path+e.enumber+"/"+e.enumber.upcase+"*").each do |f|
               # need to exclude directories - so not pick up the dicom dirs
               if File.file?(f)
                 v_file_name = f.gsub(v_path+e.enumber+"/","")
                 v_cnt = v_cnt + 1
               end
            end   
            if v_cnt < 1
              Dir.glob(v_path+e.enumber+"/"+"*"+e.enumber[1..-1].upcase+"*.img").each do |f|
                 v_file_name = f.gsub(v_path+e.enumber+"/","")
                 v_cnt = v_cnt + 1
              end
            end
            if v_cnt > 1
              v_file_name = ""
            end 
            # old check without enumber dir in path
          elsif !Dir.glob(v_path+e.enumber+"*").empty?   or !Dir.glob(v_path+"*"+e.enumber[1..-1]+"*.img").empty?
            v_cnt = 0
            Dir.glob(v_path+e.enumber+"*").each do |f|
               # need to exclude directories - so not pick up the dicom dirs
               if File.file?(f)
                 v_file_name = f.gsub(v_path,"")
                 v_cnt = v_cnt + 1
               end
            end   
            if v_cnt < 1
              Dir.glob(v_path+"*"+e.enumber[1..-1]+"*.img").each do |f|
                 v_file_name = f.gsub(v_path,"")
                 v_cnt = v_cnt + 1
              end
            end
            if v_cnt > 1
              v_file_name = ""
            end 
          elsif !Dir.glob(v_path+e.enumber.upcase+"*").empty?   or !Dir.glob(v_path+"*"+e.enumber[1..-1].upcase+"*.img").empty?
            v_cnt = 0
            Dir.glob(v_path+e.enumber.upcase+"*").each do |f|
               # need to exclude directories - so not pick up the dicom dirs
               if File.file?(f)
                 v_file_name = f.gsub(v_path,"")
                 v_cnt = v_cnt + 1
               end
            end   
            if v_cnt < 1
              Dir.glob(v_path+"*"+e.enumber[1..-1].upcase+"*.img").each do |f|
                 v_file_name = f.gsub(v_path,"")
                 v_cnt = v_cnt + 1
              end
            end
            if v_cnt > 1
              v_file_name = ""
            end 


           else    
          end
        end
    else
        #puts "AAAAAAAAA "+v_key+"   no path for sp in hash"
    end
    return v_file_name
  end
  # need to get multiple pet dicoms
  def get_pet_dicoms(p_sp_id, p_tracer_id, p_vgroup_id,p_exclude_path_array)

puts "hhhhh p_exclude_path_array="+p_exclude_path_array.join(";       ")

    v_base_path = Shared.get_base_path()
    v_sp = ScanProcedure.find(p_sp_id)
    v_pet_target_path = ""
    if !v_sp.petscan_tracer_path.blank?
      v_tracer_path_array = v_sp.petscan_tracer_path.split("|")
      v_tracer_path_array.each do |tr|
        v_tracer_path = tr.split(":")
        if v_tracer_path[0] == p_tracer_id.to_s
            v_pet_target_path = v_tracer_path[1]
        end
      end
    end
    #v_key = p_tracer_id.to_s+"_"+v_sp.codename
    v_directory_names = []
    if !v_pet_target_path.blank? #v_pet_target_hash[v_key].blank?
puts "fffff !v_pet_target_path.blank?"
        v_path = v_base_path+"/raw/"+v_pet_target_path+"/" #v_pet_target_hash[v_key]+"/"
        # check for file with enum 
        vgroup = Vgroup.find(p_vgroup_id)
        (vgroup.enrollments).each do |e|   # need case insensitive match 
          # adcp#### needs to be adcp_##### for pattern match
          v_enumber = e.enumber
          if (e.enumber).start_with? "adcp"
               v_enumber = v_enumber.gsub("_","")
               v_last_four_chars = (e.enumber)[-4..-1]
               if !v_last_four_chars.include? "_" and  v_last_four_chars =~ /^[0-9]+$/ 
                      e.enumber = "adcp_"+v_last_four_chars #in the file name but not in the pet/enumber dir
                      v_enumber = e.enumber.gsub("_","")
              end
          end
          # check for dicoms
          v_check_path = v_path+v_enumber #+"/dicoms/" # change to just look for a directory -- "/0*/" ??? but exclude lose ecat file
          if Dir.exist?(v_check_path)
            # look for I*.dcm* 
            # if not find look for dicoms another 3 levels down
             # look for I*.dcm*  in sub folder
            Dir.glob(v_check_path+"*").select {|f| 
              Dir.glob(f+"/*").each do |leaf|
              branch = leaf
      puts "aaaaa leaf="+leaf.to_s
      puts "dir="+(File.dirname(leaf.to_s)).to_s
              if leaf.to_s =~ /^I\..*(\.bz2)?$|\.dcm(\.bz2)?$|\.[0-9]{2,}(\.bz2)?$/ and !p_exclude_path_array.include?(File.dirname(leaf.to_s).to_s)
                lc = local_copy(leaf)
                # path to copy of dcm in /tmp
                # read dicom header
               puts "aaggggg dcm path local="+lc.to_s
               header = create_dicom_taghash(DICOM::DObject.read(lc.to_s))
    puts "A header="+header.to_s

                begin
                  yield lc
                rescue Exception => e
                  puts "#{e}"
                ensure
                lc.delete
                end
                return leaf,header
              end 
             end
              Dir.glob(f+"/*/*").each do |leaf|
              branch = leaf
    puts "B leaf.to_s="+leaf.to_s
    puts "b p_exclude_path_array="+p_exclude_path_array.join("::: ")
    if !p_exclude_path_array.include?(File.dirname(leaf.to_s).to_s)
      puts "B not in exclude"
    else
      puts "B in exclude"
    end
              if leaf.to_s =~ /^I\..*(\.bz2)?$|\.dcm(\.bz2)?$|\.[0-9]{2,}(\.bz2)?$/ and !p_exclude_path_array.include?(File.dirname(leaf.to_s).to_s)
                lc = local_copy(leaf)
                # path to copy of dcm in /tmp
                # read dicom header
               puts "bbbggggg dcm path local="+lc.to_s
               header = create_dicom_taghash(DICOM::DObject.read(lc.to_s))
    puts "Bheader="+header.to_s

                begin
                  yield lc
                rescue Exception => e
                  puts "#{e}"
                ensure
                lc.delete
                end
                return leaf,header
              end 
             end
              Dir.glob(f+"/*/*/*").each do |leaf|
              branch = leaf
              if leaf.to_s =~ /^I\..*(\.bz2)?$|\.dcm(\.bz2)?$|\.[0-9]{2,}(\.bz2)?$/ and !p_exclude_path_array.include?(File.dirname(leaf.to_s).to_s)
                lc = local_copy(leaf)
                # path to copy of dcm in /tmp
                # read dicom header
               puts "cccggggg dcm path local="+lc.to_s
               header = create_dicom_taghash(DICOM::DObject.read(lc.to_s))
    puts "Cheader="+header.to_s


                begin
                  yield lc
                rescue Exception => e
                  puts "#{e}"
                ensure
                lc.delete
                end
                return leaf,header
              end 
             end
              Dir.glob(f+"/*/*/*/*").each do |leaf|
              branch = leaf
              if leaf.to_s =~ /^I\..*(\.bz2)?$|\.dcm(\.bz2)?$|\.[0-9]{2,}(\.bz2)?$/ and !p_exclude_path_array.include?(File.dirname(leaf.to_s).to_s)
                lc = local_copy(leaf)
                # path to copy of dcm in /tmp
                # read dicom header
               puts "dddggggg dcm path local="+lc.to_s
               header = create_dicom_taghash(DICOM::DObject.read(lc.to_s))
    puts "Dheader="+header.to_s

                begin
                  yield lc
                rescue Exception => e
                  puts "#{e}"
                ensure
                lc.delete
                end
                return leaf,header
              end 
             end

            }
              
            


          end
        end
    else
        #puts "AAAAAAAAA "+v_key+"   no path for sp in hash"
    end
    return v_directory_names
  end
  # from metamri core_additions
  def first_dicom
    entries.each do |leaf|
      branch = self + leaf
      if leaf.to_s =~ /^I\..*(\.bz2)?$|\.dcm(\.bz2)?$|\.[0-9]{2,}(\.bz2)?$/
        lc = branch.local_copy
        begin
          yield lc
        rescue Exception => e
          puts "#{e}"
        ensure
          lc.delete
        end
        return
      end 
    end
  end

   # from metamri core_additions
  # Creates a local, unzipped copy of a file for use in scanning.
  # Will return a pathname to the local copy if called directly, or can also be 
  # passed a block.  If it is passed a block, it will create the local copy
  # and ensure the local copy is deleted.
  def local_copy(p_source_file, tempdir = Dir.mktmpdir, &block)
    tfbase = p_source_file
    tfbase = p_source_file.to_s =~ /\.bz2$/ ? File.basename(p_source_file).to_s.chomp(".bz2") : File.basename(p_source_file).to_s
    tfbase.escape_filename
    tmpfile = File.join(tempdir, tfbase)
     puts "tmpfile="+tmpfile
    # puts File.exist?(tmpfile)
    File.delete(tmpfile) if File.exist?(tmpfile)
    if p_source_file.to_s =~ /\.bz2$/
      `bunzip2 -k -c '#{p_source_file.to_s}' >> '#{tmpfile}'`
    else
      FileUtils.cp(p_source_file.to_s, tmpfile)
    end

    lc = Pathname.new(tmpfile)
    
    if block
      begin
        yield lc
      ensure
        lc.delete
      end

    else
      return lc
    end
  end

  

  # MORE THAN ONE FILE!!!!!!
  def get_pet_files(p_sp_id, p_tracer_id, p_vgroup_id)
    # ???? '1_asthana.adrc-clinical-core.visit1'=>'', '2_bendlin.tami.visit1'=>'', '1_bendlin.wmad.visit1'=>'','1_bendlin.mets.visit1'=> '',    '2_bendlin.mets.visit1'=> ''
    # 2_ries.mosaic.visit1    3_ries.mosaic.visit1
    # tracer 1=pib, 2=fdg, 3=way, 4=015
    v_base_path = Shared.get_base_path()
    v_sp = ScanProcedure.find(p_sp_id)
    v_pet_target_path = ""
    if !v_sp.petscan_tracer_path.blank?
      v_tracer_path_array = v_sp.petscan_tracer_path.split("|")
      v_tracer_path_array.each do |tr|
        v_tracer_path = tr.split(":")
        if v_tracer_path[0] == p_tracer_id.to_s
            v_pet_target_path = v_tracer_path[1]
        end
      end
    end

    #v_key = p_tracer_id.to_s+"_"+v_sp.codename
    v_file_names = []
    if !v_pet_target_path.blank? #v_pet_target_hash[v_key].blank?
        v_path = v_base_path+"/raw/"+v_pet_target_path+"/" #v_pet_target_hash[v_key]+"/"
        # check for file with enum 
        vgroup = Vgroup.find(p_vgroup_id)
        (vgroup.enrollments).each do |e|   # need case insensitive match 
          # adcp#### needs to be adcp_##### for pattern match
          v_enumber = e.enumber
          if (e.enumber).start_with? "adcp"
               v_enumber = v_enumber.gsub("_","")
               v_last_four_chars = (e.enumber)[-4..-1]
               if !v_last_four_chars.include? "_" and  v_last_four_chars =~ /^[0-9]+$/ 
                      e.enumber = "adcp_"+v_last_four_chars #in the file name but not in the pet/enumber dir
              end
          end

          # checking first for the enum dir in path, then the puddle of files
          # add the dicom petfile detection
          # only in subject_directory - maybe with the exam number/date for adni and adcp?
          # dicoms/<scan_series_number>/I####.dcm.bz2
          # bunzip2 into tmp - how does metmri read bunzip2 and dicoms - do it the same way without using metamri
          # add a petscans_file dicom headewr blob
          # display at the petscan file level
          # populate as many fields as possible
          if !Dir.glob(v_path+v_enumber+"/"+e.enumber+"*", File::FNM_CASEFOLD).empty?   or !Dir.glob(v_path+v_enumber+"/"+"*"+e.enumber[1..-1]+"*.img", File::FNM_CASEFOLD).empty?
            v_cnt = 0
            Dir.glob(v_path+v_enumber+"/"+e.enumber+"*", File::FNM_CASEFOLD).each do |f|
              # need to exclude directories - so not pick up the dicom dirs
               if File.file?(f)
                 v_file_names.push(f.gsub(v_path+v_enumber+"/",""))
                 v_cnt = v_cnt + 1
               end
            end   
            if v_cnt < 1
              Dir.glob(v_path+v_enumber+"/"+"*"+e.enumber[1..-1]+"*.img", File::FNM_CASEFOLD).each do |f|
                 v_file_names.push(f.gsub(v_path+v_enumber+"/",""))
                 v_cnt = v_cnt + 1
              end
            end
          elsif !Dir.glob(v_path+e.enumber+"*", File::FNM_CASEFOLD).empty?   or !Dir.glob(v_path+"*"+e.enumber[1..-1]+"*.img", File::FNM_CASEFOLD).empty?
            v_cnt = 0
            Dir.glob(v_path+e.enumber+"*", File::FNM_CASEFOLD).each do |f|
              # need to exclude directories - so not pick up the dicom dirs
              if File.file?(f)
                 v_file_names.push(f.gsub(v_path,""))
                 v_cnt = v_cnt + 1
               end
            end   
            if v_cnt < 1
              Dir.glob(v_path+"*"+e.enumber[1..-1]+"*.img", File::FNM_CASEFOLD).each do |f|
                 v_file_names.push(f.gsub(v_path,""))
                 v_cnt = v_cnt + 1
              end
            end  
          end
        end
    else
        #puts "AAAAAAAAA "+v_key+"   no path for sp in hash"
    end
    return v_file_names
  end
  
  def get_pet_path(p_sp_id, p_file_name, p_tracer_id,p_vgroup_id)
    # ???? '1_asthana.adrc-clinical-core.visit1'=>'', '2_bendlin.tami.visit1'=>'', '1_bendlin.wmad.visit1'=>'','1_bendlin.mets.visit1'=> '',    '2_bendlin.mets.visit1'=> ''
    # 2_ries.mosaic.visit1    3_ries.mosaic.visit1
    # tracer 1=pib, 2=fdg, 3=way, 4=015
    v_base_path = Shared.get_base_path()
    #v_pet_target_hash ={'1_johnson.pipr.visit1'=>'johnson.pipr.visit1/pet','2_johnson.predict.visit1'=>'johnson.predict.visit1/pet/FDG-visit1',
    #     '1_johnson.predict.visit1'=>'johnson.predict.visit1/pet/PIB-visit1','2_johnson.predict.visit2'=>'johnson.predict.visit2/pet/FDG',
    #     '1_johnson.predict.visit2'=>'johnson.predict.visit2/pet/PIB','2_johnson.rhesus.visit2'=>'johnson.rhesus.visit2/pet/FDG',
    #     '2_ries.mosaic.visit1'=>'ries.mosaic.visit1/pet/FDG',    '3_ries.mosaic.visit1'=>'ries.mosaic.visit1/pet/WAY',
    #     '2_johnson.rhesus.visit2'=>'johnson.rhesus.visit2/pet/FDG',
    #     '5_bendlin.pbr28.visit1'=>'bendlin.pbr28.visit1/pet/PBR',
    #      '2_ADNI-2'=>'ADNI-2/pet/FDG', 
    #       '6_ADNI-2'=>'ADNI-2/pet/AV45' }
    v_sp = ScanProcedure.find(p_sp_id)
    v_pet_target_path = ""
    if !v_sp.petscan_tracer_path.blank?
      v_tracer_path_array = v_sp.petscan_tracer_path.split("|")
      v_tracer_path_array.each do |tr|
          v_tracer_path = tr.split(":")
          if v_tracer_path[0] == p_tracer_id.to_s
              v_pet_target_path = v_tracer_path[1]
          end
      end
     end
    #v_key = p_tracer_id.to_s+"_"+v_sp.codename
    v_path = ""
    if !v_pet_target_path.blank?
        v_path = v_base_path+"/raw/"+v_pet_target_path+"/"+p_file_name
    else
        puts "AAAAAAAAA "+p_tracer_id.to_s+"_"+v_sp.codename+"   "+p_file_name
    end
    if File.exists?(v_path)
      return v_path
    else # need to check for enum directory - new structure - should be doing before the puddle check
      vgroup = Vgroup.find(p_vgroup_id)
      (vgroup.enrollments).each do |e| 
          v_path = v_base_path+"/raw/"+v_pet_target_path+"/"+e.enumber+"/"+p_file_name
          if File.exists?(v_path)
             return v_path
          end
      end

      return ""
    end
  end
  
  def petscan_appointment_date
      @appointment =Appointment.find(self.appointment_id)
      return @appointment.appointment_date
  end

 def create_dicom_taghash(header)
    raise ScriptError, "A DICOM::DObject instance is required" unless header.kind_of? DICOM::DObject
    h = Hash.new
    header.children.each do |element|
      h[element.tag] = {:value => element.instance_variable_get(:@value), :name => element.name}
    end
    return h
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
