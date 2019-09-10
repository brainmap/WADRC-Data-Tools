require 'tmpdir'
require 'dicom'

# What's this sort thing here for? We use it in some of the PET file finding -- we want to 
# sort a list of files in a directory, because we would prefer to use peer corrected
# files (their filenames have "PU"), and would prefer to discourage "ORIG" files.

def path_sort(a,b)
  if !a.scan(/PU/).blank? and !b.scan(/PU/).blank?
    return 0
  elsif !a.scan(/ORIG/).blank? and !b.scan(/ORIG/).blank?
    return 0
  elsif !a.scan(/PU/).blank?
    return -1
  elsif !a.scan(/ORIG/).blank?
    return 1
  elsif !b.scan(/PU/).blank?
    return 1
  elsif !b.scan(/ORIG/).blank?
    return -1
  else
    return 0
  end
end

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
  # if the pet files are not being detected,
  # check the scan_procedure.[Petscan tracer path] field- the file detect uses the expected pet tracer path, defined in the scan_procedure of the scan
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

  def petfiles
    @petfiles ||= Petfile.where("petscan_id = ?", self.id)
    @petfiles
  end

  def pet_path
    case petfiles.count
      when 0 then return ''
      when 1 then return petfiles.first.path
      else return petfiles.last.path
    end
    return ''
  end

  def paths_ok?
    #paths_ok implies that:
    # => if there's only one, it's a file or a directory
    # => if there are multiple petfiles, they're all directories
    #scan_files = Petfile.where("petscan_id = ?", self.id)

    v_petfiles_pass = true

    case petfiles.count
      when 0 then return false
      when 1 then v_petfiles_pass = petfiles.first.path_ok?
      else v_petfiles_pass = petfiles.all? { |f| f.path_ok? && f.path_dir? }
    end

    v_path_array = pet_path.split('/')
    if v_path_array.count > 10
      return false
    end

    #if we can't find anything else wrong with these paths, then we're probably ok, 
    # but as soon as we find a new failing case, this is where new tests should go
    return v_petfiles_pass
  end

  def preprocessed_dir_exists?(dir_name='/pet/pib/dvr/code_ver2b')

    # If this directory exists in preprocessed, that means that this isn't the first time 
    # the files have been processed. If we're doing reprocessing, that's ok, and we should
    # continue. If we're doing initial processing, skip this one.

    if pet_path.nil?
      return false
    end

    if pet_path.split("/").length < 9
      return false
    end

    #some pet paths are paths to an ecat file, which should end with ".v". These we've got
    # get the subject id by cutting it out of the ecat name.
    v_subjectid = ''
    v_path_array = pet_path.split('/')

    if File.exist?(pet_path) and !File.directory?(pet_path) and pet_path.end_with?(".v")
      v_subjectid_array = v_path_array[-1].split("_")
      v_subjectid = v_subjectid_array[0].downcase

    #others are paths to a directory under raw. these should have a subject id as a directory
    # in the middle of their path
    elsif File.directory?(pet_path)
      v_subjectid = v_path_array[7]
    else
      return false
    end

    v_base_path = Shared.get_base_path()
    v_preprocessed_path = v_base_path+"/preprocessed/visits/"

    v_scan_procedure_codename = v_path_array[4]

    v_subjectid_pet_pib_processed_path = v_preprocessed_path + v_scan_procedure_codename + "/" + v_subjectid + dir_name

    #puts "check path: #{v_subjectid_pet_pib_processed_path} (id:#{self.id})"

    return File.directory?(v_subjectid_pet_pib_processed_path)

  end

  def paths_ok!
    #like paths_ok?, but raises errors that should be caught by the calling function to diagnose weird/bad petfile records
    #scan_files = Petfile.where("petscan_id = ?", self.id)

    v_petfiles_pass = true

    case petfiles.count
      when 0 then
        begin
          raise Exceptions::PetscanNoEcatsError, "No Petfile records exist."
        end
      when 1 then
        begin
          if !petfiles.first.path_ok?
            if petfiles.first.nil?
              raise Exceptions::PetscanPathError, "The only Petfile has a nil path."
            elsif petfiles.first.blank?
              raise Exceptions::PetscanPathError, "The only Petfile has a blank path."
            elsif !File.directory?(petfiles.first.path) && !File.file?(petfiles.first.path)
              raise Exceptions::PetscanPathError, "The only Petfile has a path, but it's neither a file nor a directory. '#{petfiles.first.path}'"
            else
              raise Exceptions::PetscanError, "Some other error with the Petfile."
            end
          end
        end
      else
        if !petfiles.all? { |f| f.path_ok? && f.path_dir? }
          #multiple ecat files?
          if petfiles.map { |f| if f.file_name.end_with?(".v"); then true; end }.compact.length > 1
            raise Exceptions::PetscanTooManyEcatsError, "Multiple Ecat files."
          end

          petfiles.each do |f|
            if !f.path_ok?
              raise Exceptions::PetscanPathError, "Petfile's path wasn't ok: '#{f.path}'."
            elsif !f.path_dir?
              raise Exceptions::PetscanTooManyEcatsError, "Petfile's path wasn't a directory: '#{f.path}'."
            else
              raise Exceptions::PetscanError, "Some other error with a Petfile."
            end
          end
        end
    end

    v_path_array = pet_path.split('/')
    if v_path_array.count > 10
      raise Exceptions::PetscanPathError, "Petfile's path was too long: '#{pet_path}'."
    end

    return v_petfiles_pass

  end

  def related_enumber
    if pet_path.nil?
      return nil
    end
    if @v_enumber.nil?

      v_subjectid = ''
      v_path_array = pet_path.split('/')

      if File.exist?(pet_path) and !File.directory?(pet_path) and pet_path.end_with?(".v")
        v_subjectid_array = v_path_array[-1].split("_")
        v_subjectid = v_subjectid_array[0].downcase

      #others are paths to a directory under raw. these should have a subject id as a directory
      # in the middle of their path
      elsif File.directory?(pet_path)
        v_subjectid = v_path_array[7]
      end
      
      v_enumbers = Enrollment.where("enumber in (?)", v_subjectid)
      if v_enumbers.count <= 0
        return nil
      else
        @v_enumber = v_enumbers.first
      end
    end
    return @v_enumber
  end


  def related_scan_procedure
    if pet_path.nil?
      return nil
    end
    if @v_scan_procedure.nil?
      v_path_array = pet_path.split('/')
      v_scan_procedure_codename = v_path_array[4]
      v_scan_procedures = ScanProcedure.where("codename in (?)",v_scan_procedure_codename)
      if v_scan_procedures.count <= 0
        return nil
      else
        @v_scan_procedure = v_scan_procedures.first
      end
    end
    return @v_scan_procedure
  end

  def related_appointment
    if pet_path.nil?
      return nil
    end
    if @v_appointment.nil?
      v_appointment = Appointment.where("id in (?)",appointment_id)
      if v_appointment.count <= 0
        return nil
      else
        @v_appointment = v_appointment.first
      end
    end
    return @v_appointment
  end

  def related_participant
    if pet_path.nil?
      return nil
    end
    if @v_participant.nil?
      @v_participant = Participant.find(Vgroup.find(related_appointment.vgroup_id).participant_id)
      # if v_scan_procedures.count <= 0
      #   return nil
      # else
      #   @v_scan_procedure = v_scan_procedures.first
      # end
    end
    return @v_participant
  end


  def o_acpc_file_exists?
    v_base_path = Shared.get_base_path()
    v_preprocessed_path = v_base_path+"/preprocessed/visits/"

    if related_enumber.nil? or related_scan_procedure.nil?
      return false
    end

    v_subjectid_tissue_seg = v_preprocessed_path+related_scan_procedure.codename+"/"+related_enumber.enumber+"/unknown"
    # puts "checking "+v_subjectid_tissue_seg
    if File.directory?(v_subjectid_tissue_seg)
      v_matching_files = Dir.entries(v_subjectid_tissue_seg).select { |f| f.start_with?("o") and f.end_with?(".nii") }
      if v_matching_files.length == 0
        #not enough o_acpc.nii files
        return false
      elsif v_matching_files.length == 1
        #just right
        return true
      else
        #too many o_acpc.nii files
        return false
      end
    end

    #we didn't find a file, so
    return false
  end

  def get_o_acpc_file
    v_base_path = Shared.get_base_path()
    v_preprocessed_path = v_base_path+"/preprocessed/visits/"

    v_subjectid_tissue_seg = v_preprocessed_path+related_scan_procedure.codename+"/"+related_enumber.enumber+"/unknown"
    if File.directory?(v_subjectid_tissue_seg)
      file_entries = Dir.entries(v_subjectid_tissue_seg)
      file_entries.sort!{|a,b| path_sort(a,b)} #This will upsort peer corrected "PU" files, and downsort "ORIG" files
      file_entries.each do |f|
        if f.start_with?("o") and f.end_with?(".nii")
          return "#{v_subjectid_tissue_seg}/#{f}"
        end
      end
    end

    #we didn't find a file, so
    return false
  end

  def appropriate_T2?(filename)
    if filename.include?('-T2-') and filename.end_with?(".nii")
      if filename.include?('ORIG')
        return true
      elsif filename.include?('PU')
        return true
      elsif filename.include?('CUBE-T2')
        return true
      elsif filename.include?('CUBE-Flair') or filename.include?('CUBE-FLAIR')
        return true
      end
    end
    return false
  end

  def multispectral_file_exists?
    v_base_path = Shared.get_base_path()
    v_preprocessed_path = v_base_path+"/preprocessed/visits/"

    if related_enumber.nil? or related_scan_procedure.nil?
      return false
    end

    v_subjectid_tissue_seg = v_preprocessed_path+related_scan_procedure.codename+"/"+related_enumber.enumber+"/unknown"
    
    if File.directory?(v_subjectid_tissue_seg)

      v_matching_files = Dir.entries(v_subjectid_tissue_seg).select { |f| appropriate_T2?(f) }

      if v_matching_files.length > 0
        return true
      end
    end

    #we didn't find a file, so
    return false
  end

  def get_multispectral_file
    v_base_path = Shared.get_base_path()
    v_preprocessed_path = v_base_path+"/preprocessed/visits/"

    v_subjectid_tissue_seg = v_preprocessed_path+related_scan_procedure.codename+"/"+related_enumber.enumber+"/unknown"
    if File.directory?(v_subjectid_tissue_seg)
      file_entries = Dir.entries(v_subjectid_tissue_seg)
      file_entries.sort!{|a,b| path_sort(a,b)} #This will upsort peer corrected "PU" files, and downsort "ORIG" files
      file_entries.each do |f|
        if appropriate_T2?(f)
          return "#{v_subjectid_tissue_seg}/#{f}"
        end
      end
    end

    #we didn't find a file, so
    return false
  end


  def recent_o_acpc_file_exists?(v_mri_visits)

    v_base_path = Shared.get_base_path()
    v_preprocessed_path = v_base_path+"/preprocessed/visits/"

    v_mri_visits.each do |mri_visit|
      if mri_visit.path.include?("adcp")
        next
      end

      v_raw_path_array = (mri_visit.path).gsub(v_base_path+"/raw/","").split("/")
      if v_raw_path_array.include?("mri")
        v_other_mri_unknown = v_preprocessed_path+v_raw_path_array[0]+"/"+(v_raw_path_array[2].split("_"))[0]+"/unknown"
      else
        v_other_mri_unknown = v_preprocessed_path+v_raw_path_array[0]+"/"+(v_raw_path_array[1].split("_"))[0]+"/unknown"
      end

      if File.directory?(v_other_mri_unknown)
        v_matching_files = Dir.entries(v_other_mri_unknown).select { |f| f.start_with?("o") and f.end_with?(".nii") }
        if v_matching_files.length == 1
          return true
        end
      end

    end

    #we didn't find a file, so
    return false
  end

  def get_recent_o_acpc_file(v_mri_visits)
    v_base_path = Shared.get_base_path()
    v_preprocessed_path = v_base_path+"/preprocessed/visits/"

    v_mri_visits.each do |mri_visit|
      if mri_visit.path.include?("adcp")
        next
      end

      v_raw_path_array = (mri_visit.path).gsub(v_base_path+"/raw/","").split("/")
      if v_raw_path_array.include?("mri")
        v_other_mri_unknown = v_preprocessed_path+v_raw_path_array[0]+"/"+(v_raw_path_array[2].split("_"))[0]+"/unknown"
      else
        v_other_mri_unknown = v_preprocessed_path+v_raw_path_array[0]+"/"+(v_raw_path_array[1].split("_"))[0]+"/unknown"
      end

      if File.directory?(v_other_mri_unknown)
        Dir.entries(v_other_mri_unknown).each do |f|
          if f.start_with?("o") and f.end_with?(".nii")
            return "#{v_other_mri_unknown}/#{f}"
          end
        end
      end

    end

    #we didn't find a file, so
    return false
  end

  def recent_multispectral_file_exists?(v_mri_visits)
    v_base_path = Shared.get_base_path()
    v_preprocessed_path = v_base_path+"/preprocessed/visits/"

    if related_enumber.nil? or related_scan_procedure.nil?
      return false
    end

    v_mri_visits.each do |mri_visit|
      if mri_visit.path.include?("adcp")
        next
      end

      v_raw_path_array = (mri_visit.path).gsub(v_base_path+"/raw/","").split("/")
      if v_raw_path_array.include?("mri")
        v_other_mri_unknown = v_preprocessed_path+v_raw_path_array[0]+"/"+(v_raw_path_array[2].split("_"))[0]+"/unknown"
      else
        v_other_mri_unknown = v_preprocessed_path+v_raw_path_array[0]+"/"+(v_raw_path_array[1].split("_"))[0]+"/unknown"
      end

      if File.directory?(v_other_mri_unknown)

        v_matching_files = Dir.entries(v_other_mri_unknown).select { |f| appropriate_T2?(f) }

        if v_matching_files.length > 0
          return true
        end
      end
    end

    #we didn't find a file, so
    return false
  end

  def get_recent_multispectral_file(v_mri_visits)
    v_base_path = Shared.get_base_path()
    v_preprocessed_path = v_base_path+"/preprocessed/visits/"

    v_mri_visits.each do |mri_visit|
      if mri_visit.path.include?("adcp")
        next
      end

      v_raw_path_array = (mri_visit.path).gsub(v_base_path+"/raw/","").split("/")
      if v_raw_path_array.include?("mri")
        v_other_mri_unknown = v_preprocessed_path+v_raw_path_array[0]+"/"+(v_raw_path_array[2].split("_"))[0]+"/unknown"
      else
        v_other_mri_unknown = v_preprocessed_path+v_raw_path_array[0]+"/"+(v_raw_path_array[1].split("_"))[0]+"/unknown"
      end

      if File.directory?(v_other_mri_unknown)
        Dir.entries(v_other_mri_unknown).each do |f|
          if appropriate_T2?(f)
            return "#{v_other_mri_unknown}/#{f}"
          end
        end
      end
    end

    #we didn't find a file, so
    return false
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
