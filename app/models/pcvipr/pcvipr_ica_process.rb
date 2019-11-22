class Pcvipr::PcviprIcaProcess < Pcvipr::PcviprBase

  def self.default_params
    params = { schedule_name: 'pcvipr_ica_process',
        base_path: Shared.get_base_path(), 
          computer: "kanga",
          comment: [],
          comment_warning: ""
        }
        params.default = ''
        params
    end

    def run(p=@params)

         v_base_path = Shared.get_base_path()
          v_comment = ""
          v_computer = "kanga" # actually baloo == v_machine
           v_machine = "baloo.dom.wisc.edu"  # eventually switch to "+v_computer+" - need packages installed
          v_cnt = 0
          v_rerun_outputs = "N" #"Y"# rm output and log if output present
          v_rerun_full_outputs_log = "N"  # "Y"  # rm all output and log  
          v_rerun_if_no_output = "N"
          # if p_output_log_rm == "rm_output"
          #   v_rerun_outputs = "Y"
          #   v_rerun_if_no_output = "Y"
          # end  
          # if p_output_log_rm == "rm_output_and_log"
          #   v_rerun_if_no_output = "Y"
          #   v_rerun_outputs = "Y"
          # end
          # if p_output_log_rm == "rerun_if_no_output"
          #   v_rerun_if_no_output = "Y"
          # end

         #  v_script_path = v_base_path+"/data1/lab_scripts/python_dev/collect_pcvipr_data.py" 
          v_script_path = v_base_path+"/SysAdmin/production/python/collect_pcvipr_ICA_QmeanCurves.py"  # CHANGE TO PRODUCTION

          # add check if output.csv was made
          #connection = ActiveRecord::Base.connection();

          v_analyses_path = v_base_path+"/analyses/PCVIPR/4DFLOW_DATA/"

          # go to directory, get list of directories. - could check if there is a scan_procedure
          Dir.glob(v_analyses_path+"/*").each do |v_dir_path_name| 
            if File.directory?(v_dir_path_name)
                #puts v_dir_path_name
               v_scan_procedures = ScanProcedure.where("scan_procedures.codename in (?)",v_dir_path_name.split("/").last)
               if !v_scan_procedures.nil? and !v_scan_procedures[0].nil?
                  #puts v_scan_procedures[0].codename
                  v_dir_path_name_done = v_dir_path_name+"/"+v_dir_path_name.split("/").last+".done"
                  puts "v_dir_path_name_done= "+v_dir_path_name_done
                  Dir.glob(v_dir_path_name_done+"/*").each do |v_dir_path_name_subjectid| # get the subjectid folders
                    # check for Summary.xls and *Summary_Calculator_*.xlsx and output*.csv
                    #NEED TO DO FIND or something to get real path
                    # get path to Summary.xls, could be few directories down

                    
                    if  !Dir.glob(v_dir_path_name_subjectid+"/Summary.xls").empty?  and !Dir.glob(v_dir_path_name_subjectid+"/*Summary_Calculator_*.xlsx").empty?
                        #puts "done===="+v_dir_path_name_subjectid
                        v_just_path = v_dir_path_name_subjectid
                        # run command
                        v_call = "ssh panda_user@"+v_machine+" '"+v_script_path+"  "+v_just_path+"' "
                        #puts v_call
                        stdin, stdout, stderr = Open3.popen3(v_call)
                        
                        while !stdout.eof?
                            puts stdout.read 1024    
                        end
                        stdin.close
                        stdout.close
                        stderr.close
                        if Dir.glob(v_dir_path_name_subjectid+"/*_ICA_QmeanCurve.csv").empty?
                                v_comment = v_comment+"; no output file="+v_just_path.gsub!(v_dir_path_name_done,'')
                        else
                          v_cnt = v_cnt +1
                        end

                     elsif  !Dir.glob(v_dir_path_name_subjectid+"/*/Summary.xls").empty?  and !Dir.glob(v_dir_path_name_subjectid+"/*/*Summary_Calculator_*.xlsx").empty?
                         #puts "done 1 down===="+v_dir_path_name_subjectid+"/*"
                         # get extra dir path 
                         Dir.glob(v_dir_path_name_subjectid+"/*/Summary.xls").each do |v_file_path| 
                             v_just_path = File.dirname(v_file_path)
                             #puts v_just_path
                             # run command
                             v_call = "ssh panda_user@"+v_machine+" '"+v_script_path+"  "+v_just_path+"' "
                            #puts v_call
                             stdin, stdout, stderr = Open3.popen3(v_call)
                             while !stdout.eof?
                                puts stdout.read 1024    
                             end
                             stdin.close
                             stdout.close
                             stderr.close
                              if Dir.glob(v_dir_path_name_subjectid+"/*/*_ICA_QmeanCurve.csv").empty?
                                v_comment = v_comment+"; no output file "+v_just_path.gsub!(v_dir_path_name_done,'')
                              else
                                v_cnt = v_cnt +1
                             end
                          end
                         
                     elsif  !Dir.glob(v_dir_path_name_subjectid+"/*/*/Summary.xls").empty?  and !Dir.glob(v_dir_path_name_subjectid+"/*/*/*Summary_Calculator_*.xlsx").empty?
                         puts "done 2 down ===="+v_dir_path_name_subjectid+"/*/*"
                         # get extra dir path 
                         Dir.glob(v_dir_path_name_subjectid+"/*/*/Summary.xls").each do |v_file_path| 
                             v_just_path = File.dirname(v_file_path)
                             #puts v_just_path
                             # run command
                             v_call = "ssh panda_user@"+v_machine+" '"+v_script_path+"  "+v_just_path+"' "
                            #puts v_call
                             stdin, stdout, stderr = Open3.popen3(v_call)
                             while !stdout.eof?
                                puts stdout.read 1024    
                             end
                             stdin.close
                             stdout.close
                             stderr.close
                             if Dir.glob(v_dir_path_name_subjectid+"/*/*/*_ICA_QmeanCurve.csv").empty?
                                v_comment = v_comment+"; no output file "+v_just_path.gsub!(v_dir_path_name_done,'')
                              else
                                v_cnt = v_cnt +1
                             end
                          end
                     elsif  !Dir.glob(v_dir_path_name_subjectid+"/*/*/*/Summary.xls").empty?  and !Dir.glob(v_dir_path_name_subjectid+"/*/*/*/*Summary_Calculator_*.xlsx").empty?
                         #puts "done 3 down ===="+v_dir_path_name_subjectid+"/*/*/*"
                         # get extra dir path 
                         Dir.glob(v_dir_path_name_subjectid+"/*/*/*/Summary.xls").each do |v_file_path| 
                             v_just_path = File.dirname(v_file_path)
                             #puts v_just_path
                             # run command
                             v_call = "ssh panda_user@"+v_machine+" '"+v_script_path+"  "+v_just_path+"' "
                            #puts v_call
                             stdin, stdout, stderr = Open3.popen3(v_call)
                             while !stdout.eof?
                                puts stdout.read 1024    
                             end
                             stdin.close
                             stdout.close
                             stderr.close
                             if Dir.glob(v_dir_path_name_subjectid+"/*/*/*/*_ICA_QmeanCurve.csv").empty?
                                v_comment = v_comment+"; no output file "+v_just_path.gsub!(v_dir_path_name_done,'')
                              else
                                v_cnt = v_cnt +1
                             end
                          end
                    end
                  end
                  end
               end
            end
          end

  end