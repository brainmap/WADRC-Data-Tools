class Pcvipr::PcviprIcaHarvest < Pcvipr::PcviprBase

  def self.default_params
    params = { schedule_name: 'pcvipr_ica_harvest',
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
          v_comment =""
          v_comment_warning = ""
          v_shared = Shared.new
          v_trtype_id = 2 # pcvipr tracker typeid
          v_second_viewer_flag = "N" # populate from tracker record
          v_harvester_ignore_directory = "harvignore"
          v_computer = "kanga"

          v_file_header_expected ="regionname,centerline_point,frame0,frame1,frame2,frame3,frame4,frame5,frame6,frame7,frame8,frame9,frame10,frame11,frame12,frame13,frame14,frame15,frame16,frame17,frame18,frame19"

          v_column_list = v_file_header_expected
         # Directory Name,file_name, == dir name
          v_analyses_path = v_base_path+"/analyses/PCVIPR/4DFLOW_DATA/"
          puts "v_analyses_path="+v_analyses_path
          sql = "truncate table cg_pcvipr_ica_qmeans_values_new"
          connection = ActiveRecord::Base.connection();        
          results = connection.execute(sql)
          v_visit_number_array = ['v2','v3','v4','v5','v6','v7','v8','v9','v10','v11','v12','v13','v14','v15','v16']

          # go to directory, get list of directories. - could check if there is a scan_procedure
          Dir.glob(v_analyses_path+"/*").each do |v_dir_path_name| 
            if File.directory?(v_dir_path_name)
                puts "-bbbbb "+v_dir_path_name
                puts "sp ="+v_dir_path_name.split("/").last+"="
               v_scan_procedures = ScanProcedure.where("scan_procedures.codename in (?)",v_dir_path_name.split("/").last)
               # add check that internal subject_id sp matches top dir sp
               # add check that pcvipr has second view flag=Y


               if !v_scan_procedures.nil? and !v_scan_procedures[0].nil? #and v_dir_path_name.split("/").last == 'johnson.predict.visit3'
                  puts v_scan_procedures[0].codename
                  v_dir_path_name_done = v_dir_path_name+"/"+v_dir_path_name.split("/").last+".done"
                  puts "-aaaaaa v_dir_path_name_done= "+v_dir_path_name_done
                  Dir.glob(v_dir_path_name_done+"/*").each do |v_dir_path_name_subjectid| # get the subjectid folders
                    # check for Summary.xls and *Summary_Calculator_*.xlsx and output*.csv
                    #NEED TO DO FIND or something to get real path
                    # get path to Summary.xls, could be few directories down
                    puts "v_dir_path_name_subjectid.split(/).last="+v_dir_path_name_subjectid.split("/").last
                    v_subjectid_dir = v_dir_path_name_subjectid.split("/").last
                    v_subjectid_array = v_subjectid_dir.split("_")
                    v_subjectid = ""
                    if(!v_subjectid_array[1].nil? and (v_visit_number_array.include? v_subjectid_array[1])) # 
                       v_subjectid = v_subjectid_array[0]+"_"+v_subjectid_array[1]
                    else
                       v_subjectid = v_subjectid_array[0]
                    end
                    puts "v_subjectid="+v_subjectid+"=     v_dir_path_name_subjectid= cd "+v_dir_path_name_subjectid+"; ls *.xls*"
                    if !Dir.glob(v_dir_path_name_subjectid+"/Summary.xls").empty?  and !Dir.glob(v_dir_path_name_subjectid+"/*Summary_Calculator_*.xlsx").empty? and !Dir.glob(v_dir_path_name_subjectid+"/*_ICA_QmeanCurve.csv").empty? 
                        puts "AAAA done===="+v_dir_path_name_subjectid
                         Dir.glob(v_dir_path_name_subjectid+"/*_ICA_QmeanCurve.csv").each do |v_file_path_exact| 
                             v_file_path = v_file_path_exact # File.dirname(v_file_path_exact)
                          if v_file_path.include? v_harvester_ignore_directory
                             print "ignore this directory"
                          else
                             v_cnt = 0
                             v_header = ""
                             File.open(v_file_path,'r') do |file_a|
                               while line = file_a.gets and v_cnt < 1
                                 if v_cnt < 1
                                   v_header = line
                                 end
                                 v_cnt = v_cnt +1
                               end
                             end
                             v_return_flag,v_return_comment  = v_shared.compare_file_header(v_header,v_file_header_expected)
                             if v_return_flag == "N" 
                               v_comment = v_file_path+"=>"+v_return_comment+" \n"+v_comment
                               puts v_return_comment               
                             else
                               v_subject_id_sp_id = v_shared.get_sp_id_from_subjectid_v(v_subjectid)
                               v_second_viewer_flag = "N"
                               @trfiles = Trfile.where("trtype_id in (?)",v_trtype_id).where("subjectid in (?)",v_subjectid)
                               if !@trfiles.nil? and !@trfiles[0].nil?
                                   # get last edit
                                   @tredits = Tredit.where("trfile_id in (?) and tredits.status_flag in (?)",@trfiles[0].id, 'Y').order("tredits.id desc")
                                   v_tredit_id = @tredits[0].id
                                   # the individual fields
                                   v_tractiontypes = Tractiontype.where("trtype_id in (?)",v_trtype_id)
                                   if !v_tractiontypes.nil?
                                       v_tractiontypes.each do |tat|
                                           v_tredit_action = TreditAction.where("tredit_id in (?)",v_tredit_id).where("tractiontype_id in (?)", tat.id)
                                           if tat.id == 79 # load
                                               if  !v_tredit_action[0].nil? and !v_tredit_action[0].value.nil? and v_tredit_action[0].value == "1"
                                                   v_second_viewer_flag = "Y"
                                               end
                                            end
                                       end
                                   end
                               end
                               if v_subject_id_sp_id != v_scan_procedures[0].id   # difference between directory and subject sp - ussually a missing _v#
                                      v_comment_warning = v_comment_warning+"; sp mismatch "+v_subjectid+" sp="+v_scan_procedures[0].id .to_s
                               elsif v_second_viewer_flag == "N"
                                     ## v_comment = v_comment+"; "+v_subjectid+" not done"
                               else
                                   puts v_return_comment
                                   v_comment = v_return_comment+v_comment
                                   v_comment = v_comment[0..1499]
                                   v_cnt = 0
                                   v_line_array = []
                                   File.open(v_file_path,'r') do |file_a|
                                   while line = file_a.gets
                                     if v_cnt > 0
                                       sql = "insert into cg_pcvipr_ica_qmeans_values_new ( file_name,subjectid, "+v_column_list+" ) values('"+v_file_path.split("/").last+"','"+v_subjectid+"',"
                                       v_line_array = []
                                       line.gsub(/\n/,"").split(",").each do |v|
                                         v_line_array.push("'"+v+"'")
                                       end 
                                       sql = sql+v_line_array.join(",")
                                       sql = sql+")"
                                       results = connection.execute(sql)                    
                                     end
                                     v_cnt = v_cnt + 1
                                   end
                               end # end mismatch sp's
                             end
                            end
                          end
                        end
                        #
                     elsif  !Dir.glob(v_dir_path_name_subjectid+"/*/Summary.xls").empty?  and !Dir.glob(v_dir_path_name_subjectid+"/*/*Summary_Calculator_*.xlsx").empty? and !Dir.glob(v_dir_path_name_subjectid+"/*/*_ICA_QmeanCurve.csv").empty? 
                         puts "BBBBB done===="+v_dir_path_name_subjectid
                         Dir.glob(v_dir_path_name_subjectid+"/*/*_ICA_QmeanCurve.csv").each do |v_file_path_exact| 
                          v_file_path = v_file_path_exact #  File.dirname(v_file_path_exact)
                          if v_file_path.include? v_harvester_ignore_directory
                             print "ignore this directory"
                          else
                             v_cnt = 0
                             v_header = ""
                             File.open(v_file_path,'r') do |file_a|
                               while line = file_a.gets and v_cnt < 1
                                 if v_cnt < 1
                                   v_header = line
                                 end
                                 v_cnt = v_cnt +1
                               end
                             end
                             v_return_flag,v_return_comment  = v_shared.compare_file_header(v_header,v_file_header_expected)
                             
                             if v_return_flag == "N" 
                               v_comment = v_file_path+"=>"+v_return_comment+" \n"+v_comment
                               puts v_return_comment               
                             else
                               v_subject_id_sp_id = v_shared.get_sp_id_from_subjectid_v(v_subjectid)
                               v_second_viewer_flag = "N"
                               @trfiles = Trfile.where("trtype_id in (?)",v_trtype_id).where("subjectid in (?)",v_subjectid)
                               if !@trfiles.nil? and !@trfiles[0].nil?
                                   # get last edit
                                   @tredits = Tredit.where("trfile_id in (?) and tredits.status_flag in (?)",@trfiles[0].id,'Y').order("tredits.id desc")
                                   v_tredit_id = @tredits[0].id
                                   # the individual fields
                                   v_tractiontypes = Tractiontype.where("trtype_id in (?)",v_trtype_id)
                                   if !v_tractiontypes.nil?
                                       v_tractiontypes.each do |tat|
                                           v_tredit_action = TreditAction.where("tredit_id in (?)",v_tredit_id).where("tractiontype_id in (?)", tat.id)
                                           if tat.id == 79 # load
                                              puts "v_tredit_action is #{v_tredit_action[0].value.to_s}"
                                               if  !v_tredit_action[0].nil? and !v_tredit_action[0].value.nil? and v_tredit_action[0].value == "1"
                                                   v_second_viewer_flag = "Y"
                                               end
                                            end
                                       end
                                   end
                               end
                               puts "second_viewer_flag is #{v_second_viewer_flag}"
                               if v_subject_id_sp_id != v_scan_procedures[0].id   # difference between directory and subject sp - ussually a missing _v#
                                      v_comment_warning = v_comment_warning+"; sp mismatch "+v_subjectid+" sp="+v_scan_procedures[0].id .to_s
                               elsif v_second_viewer_flag == "N"
                                     ## v_comment = v_comment+"; "+v_subjectid+" not done"
                               else
                                   puts v_return_comment
                                   v_comment = v_return_comment+v_comment
                                   v_comment = v_comment[0..1499]
                                   v_cnt = 0
                                   v_line_array = []
                                   File.open(v_file_path,'r') do |file_a|
                                   while line = file_a.gets
                                     if v_cnt > 0
                                        puts "column list: #{v_column_list}, file_path: #{v_file_path.split("/").last}, subject id #{v_subjectid}"
                                        sql = "insert into cg_pcvipr_ica_qmeans_values_new ( file_name,subjectid, "+v_column_list+" ) values('"+v_file_path.split("/").last+"','"+v_subjectid+"',"
                                        v_line_array = []
                                        line.gsub(/\n/,"").split(",").each do |v|
                                          v_line_array.push("'"+v+"'")
                                        end 
                                        sql = sql+v_line_array.join(",")
                                        sql = sql+")"
                                        results = connection.execute(sql)                    
                                     end
                                     v_cnt = v_cnt + 1
                                   end
                                end # sp mismatch
                              end
                             end
                          end
                        end
                     elsif  !Dir.glob(v_dir_path_name_subjectid+"/*/*/Summary.xls").empty?  and !Dir.glob(v_dir_path_name_subjectid+"/*/*/*Summary_Calculator_*.xlsx").empty? and !Dir.glob(v_dir_path_name_subjectid+"/*/*/*_ICA_QmeanCurve.csv").empty? 
                         puts "CCCCCC done 2 down ===="+v_dir_path_name_subjectid+"/*/*"
                         #puts "done===="+v_dir_path_name_subjectid
                         Dir.glob(v_dir_path_name_subjectid+"/*/*/*_ICA_QmeanCurve.csv").each do |v_file_path_exact| 
                          v_file_path = v_file_path_exact #File.dirname(v_file_path_exact)
                          if v_file_path.include? v_harvester_ignore_directory
                             print "ignore this directory"
                          else
                             v_cnt = 0
                             v_header = ""
                             File.open(v_file_path,'r') do |file_a|
                               while line = file_a.gets and v_cnt < 1
                                 if v_cnt < 1
                                   v_header = line
                                 end
                                 v_cnt = v_cnt +1
                               end
                             end
                             v_return_flag,v_return_comment  = v_shared.compare_file_header(v_header,v_file_header_expected)
                             #puts "file header we got :#{v_header}"
                             if v_return_flag == "N" 
                               v_comment = v_file_path+"=>"+v_return_comment+" \n"+v_comment
                               puts v_return_comment               
                             else
                               v_subject_id_sp_id = v_shared.get_sp_id_from_subjectid_v(v_subjectid)
                               v_second_viewer_flag = "N"
                               @trfiles = Trfile.where("trtype_id in (?)",v_trtype_id).where("subjectid in (?)",v_subjectid)
                               #puts "#{@trfiles.to_sql}"
                               if !@trfiles.nil? and !@trfiles[0].nil?
                                   # get last edit
                                   @tredits = Tredit.where("trfile_id in (?) and tredits.status_flag in (?)",@trfiles[0].id,'Y').order("tredits.id desc")
                                   v_tredit_id = @tredits[0].id
                                   # the individual fields
                                   v_tractiontypes = Tractiontype.where("trtype_id in (?)",v_trtype_id)
                                   if !v_tractiontypes.nil?
                                       v_tractiontypes.each do |tat|
                                           v_tredit_action = TreditAction.where("tredit_id in (?)",v_tredit_id).where("tractiontype_id in (?)", tat.id)
                                           if tat.id == 79 # load
                                              #puts "tat.id was 79, and #{v_tredit_action[0].to_s}"
                                               if  !v_tredit_action[0].nil? and !v_tredit_action[0].value.nil? and v_tredit_action[0].value == "1"
                                                   v_second_viewer_flag = "Y"
                                               end
                                            end
                                       end
                                   end
                               end
                               if v_subject_id_sp_id != v_scan_procedures[0].id   # difference between directory and subject sp - ussually a missing _v#
                                      v_comment_warning = v_comment_warning+"; sp mismatch "+v_subjectid+" sp="+v_scan_procedures[0].id .to_s
                               elsif v_second_viewer_flag == "N"
                                     ##v_comment = v_comment+"; "+v_subjectid+" not done"
                               else
                                   puts v_return_comment
                                   v_comment = v_return_comment+v_comment
                                   v_comment = v_comment[0..1499]
                                   v_cnt = 0
                                   v_line_array = []
                                   File.open(v_file_path,'r') do |file_a|
                                   while line = file_a.gets
                                      if v_cnt > 0
                                        sql = "insert into cg_pcvipr_ica_qmeans_values_new ( file_name,subjectid, "+v_column_list+" ) values('"+v_file_path.split("/").last+"','"+v_subjectid+"',"
                                        v_line_array = []
                                        line.gsub(/\n/,"").split(",").each do |v|
                                           v_line_array.push("'"+v+"'")
                                        end 
                                        sql = sql+v_line_array.join(",")
                                        sql = sql+")"
                                        results = connection.execute(sql)                    
                                      end
                                      v_cnt = v_cnt + 1
                                   end
                                end # sp mismatch
                             end
                            end
                          end
                        end
                     elsif  !Dir.glob(v_dir_path_name_subjectid+"/*/*/*/Summary.xls").empty?  and !Dir.glob(v_dir_path_name_subjectid+"/*/*/*/*Summary_Calculator_*.xlsx").empty? and !Dir.glob(v_dir_path_name_subjectid+"/*/*/*/*_ICA_QmeanCurve.csv").empty? 
                         puts "DDDDD done 3 down ===="+v_dir_path_name_subjectid+"/*/*/*"
                         #puts "done===="+v_dir_path_name_subjectid
                         Dir.glob(v_dir_path_name_subjectid+"/*/*/*/*_ICA_QmeanCurve.csv").each do |v_file_path_exact| 
                             v_file_path = v_file_path_exact #File.dirname(v_file_path_exact)
                             v_cnt = 0
                             v_header = ""
                             File.open(v_file_path,'r') do |file_a|
                               while line = file_a.gets and v_cnt < 1
                                 if v_cnt < 1
                                   v_header = line
                                 end
                                 v_cnt = v_cnt +1
                               end
                             end
                             v_return_flag,v_return_comment  = v_shared.compare_file_header(v_header,v_file_header_expected)
                             if v_return_flag == "N" 
                               v_comment = v_file_path+"=>"+v_return_comment+" \n"+v_comment
                               puts v_return_comment               
                             else
                               v_subject_id_sp_id = v_shared.get_sp_id_from_subjectid_v(v_subjectid)
                               v_second_viewer_flag = "N"
                               @trfiles = Trfile.where("trtype_id in (?)",v_trtype_id).where("subjectid in (?)",v_subjectid)
                               if !@trfiles.nil? and !@trfiles[0].nil?
                                   # get last edit
                                   @tredits = Tredit.where("trfile_id in (?)",@trfiles[0].id).order("tredits.id desc")
                                   v_tredit_id = @tredits[0].id
                                   # the individual fields
                                   v_tractiontypes = Tractiontype.where("trtype_id in (?)",v_trtype_id)
                                   if !v_tractiontypes.nil?
                                       v_tractiontypes.each do |tat|
                                           v_tredit_action = TreditAction.where("tredit_id in (?) and tredits.status_flag in (?)",v_tredit_id,'Y').where("tractiontype_id in (?)", tat.id)
                                           if tat.id == 79 # load
                                               if  !v_tredit_action[0].nil? and !v_tredit_action[0].value.nil? and v_tredit_action[0].value == "1"
                                                   v_second_viewer_flag = "Y"
                                               end
                                            end
                                       end
                                   end
                               end
                               if v_subject_id_sp_id != v_scan_procedures[0].id   # difference between directory and subject sp - ussually a missing _v#
                                      v_comment_warning = v_comment_warning+"; sp mismatch "+v_subjectid+" sp="+v_scan_procedures[0].id .to_s
                               elsif v_second_viewer_flag == "N"
                                     ##v_comment = v_comment+"; "+v_subjectid+" not done"
                               else
                                   puts v_return_comment
                                   v_comment = v_return_comment+v_comment
                                   v_comment = v_comment[0..1499]
                                   v_cnt = 0
                                   v_line_array = []
                                   File.open(v_file_path,'r') do |file_a|
                                    while line = file_a.gets
                                     if v_cnt > 0
                                        sql = "insert into cg_pcvipr_ica_qmeans_values_new ( file_name,subjectid, "+v_column_list+" ) values('"+v_file_path.split("/").last+"','"+v_subjectid+"',"
                                        v_line_array = []
                                        line.gsub(/\n/,"").split(",").each do |v|
                                          v_line_array.push("'"+v+"'")
                                        end 
                                        sql = sql+v_line_array.join(",")
                                        sql = sql+")"
                                        results = connection.execute(sql)                    
                                     end
                                     v_cnt = v_cnt + 1
                                   end
                                end # sp mismatch
                             end
                          end
                        end
                    end
                  end
               end
            end
          end
          puts "setting the e.id"
          # update all the 
                # update enrollment -- make into a function?
                # NEED TO REPLACE THE t.subjectid based on sp.visit_number_abbreviation
                sql = "update cg_pcvipr_ica_qmeans_values_new  t set t.enrollment_id = ( select e.id from enrollments e where e.enumber = replace(replace(replace(replace(t.subjectid,'_v2',''),'_v3',''),'_v4',''),'_v5',''))"
                results = connection.execute(sql)
                # secondary key
                # select all where enrollment_id is null
                # match enumber plus .R, b, c, d , 
                # set secondary key
                sql = "select subjectid from cg_pcvipr_ica_qmeans_values_new where enrollment_id is null order by subjectid"
                results = connection.execute(sql)
                results.each do |re|
                    enrollment = Enrollment.where("concat(enumber,'.R') in (?) or concat(enumber,'a') in (?) or concat(enumber,'b') in (?) or concat(enumber,'c') in (?) or concat(enumber,'d') in (?) or concat(enumber,'e') in (?)",re[0],re[0],re[0],re[0],re[0],re[0])
                    if !enrollment.blank?
                             v_secondary_key = re[0]
                             v_secondary_key = v_secondary_key.tr(enrollment[0].enumber, "") 
                             sql = "update cg_pcvipr_ica_qmeans_values_new  t set t.enrollment_id = "+enrollment[0].id.to_s+", secondary_key='"+v_secondary_key+"', subjectid='"+enrollment[0].enumber+"' where subjectid='"+re[0]+"'"
                             results = connection.execute(sql)
                    end
                end

                

                sql = "select subjectid from cg_pcvipr_ica_qmeans_values_new"
                results = connection.execute(sql)
                results.each do |r|
                  v_sp_id = v_shared.get_sp_id_from_subjectid_v(r[0])
                  if !v_sp_id.blank?
                    sql = "update cg_pcvipr_ica_qmeans_values_new  t set t.scan_procedure_id = "+v_sp_id.to_s+" where subjectid ='"+r[0]+"'"
                    results = connection.execute(sql)
                  end
                end



                # report on unmapped rows, not insert unmapped rows 

                sql = "select subjectid, enrollment_id from cg_pcvipr_ica_qmeans_values_new where scan_procedure_id is null order by subjectid"
                results = connection.execute(sql)
                results.each do |re|
                  v_comment = re.join(' | ')+" ,"+v_comment
                end
                if !results.blank?
                   v_comment = "cg_pcvipr_ica_qmeans_values_new unmapped subjectid,enrollment_id ="+v_comment
                end
                

                # check move cg_ to cg_old
                sql = "select count(*) from cg_pcvipr_ica_qmeans_values_old"
                results_old = connection.execute(sql)
                
                sql = "select count(*) from cg_pcvipr_ica_qmeans_values"
                results = connection.execute(sql)
                v_old_cnt = results_old.first.to_s.to_i
                v_present_cnt = results.first.to_s.to_i
                v_old_minus_present =v_old_cnt-v_present_cnt
                v_present_minus_old = v_present_cnt-v_old_cnt
                if ( v_old_minus_present <= 0 or ( v_old_cnt > 0 and  (v_present_minus_old/v_old_cnt)>0.7     ) )
                  sql =  "truncate table cg_pcvipr_ica_qmeans_values_old"
                  results = connection.execute(sql)
                  sql = "insert into cg_pcvipr_ica_qmeans_values_old select * from cg_pcvipr_ica_qmeans_values"
                  results = connection.execute(sql)
                else
                  v_comment = " The cg_pcvipr_ica_qmeans_values_old table has 30% more rows than the present cg_pcvipr_ica_qmeans_values\n Not truncating cg_pcvipr_ica_qmeans_values_old "+v_comment 
                end
                #  truncate cg_ and insert cg_new
                sql =  "truncate table cg_pcvipr_ica_qmeans_values"
                results = connection.execute(sql)

                sql = "insert into cg_pcvipr_ica_qmeans_values("+v_column_list+",subjectid,enrollment_id,scan_procedure_id,secondary_key,file_name) 
                select distinct "+v_column_list+",t.subjectid,t.enrollment_id, scan_procedure_id,secondary_key,file_name from cg_pcvipr_ica_qmeans_values_new t
                                               where t.scan_procedure_id is not null  and t.enrollment_id is not null "
                results = connection.execute(sql)

                # apply edits  -- made into a function  in shared model
              
                #v_shared.apply_cg_edits("cg_pcvipr_ica_qmeans_values")
        v_comment = v_comment_warning+v_comment
        puts v_comment

  end
end

#   CREATE TABLE `cg_pcvipr_ica_qmeans_values_new` (
#   `subjectid` varchar(50) DEFAULT NULL,
#   `enrollment_id` int(11) DEFAULT NULL,
#   `scan_procedure_id` int(11) DEFAULT NULL,
#   `secondary_key` varchar(200) DEFAULT NULL,
# `regionname` varchar(50) DEFAULT NULL,
# `centerline_point` varchar(30) DEFAULT NULL,
# `frame0` varchar(30) DEFAULT NULL,
# `frame1` varchar(30) DEFAULT NULL,
# `frame2` varchar(30) DEFAULT NULL,
# `frame3` varchar(30) DEFAULT NULL,
# `frame4` varchar(30) DEFAULT NULL,
# `frame5` varchar(30) DEFAULT NULL,
# `frame6` varchar(30) DEFAULT NULL,
# `frame7` varchar(30) DEFAULT NULL,
# `frame8` varchar(30) DEFAULT NULL,
# `frame9` varchar(30) DEFAULT NULL,
# `frame10` varchar(30) DEFAULT NULL,
# `frame11` varchar(30) DEFAULT NULL,
# `frame12` varchar(30) DEFAULT NULL,
# `frame13` varchar(30) DEFAULT NULL,
# `frame14` varchar(30) DEFAULT NULL,
# `frame15` varchar(30) DEFAULT NULL,
# `frame16` varchar(30) DEFAULT NULL,
# `frame17` varchar(30) DEFAULT NULL,
# `frame18` varchar(30) DEFAULT NULL,
# `frame19` varchar(30) DEFAULT NULL,
#   `file_name` varchar(200) DEFAULT NULL
# ) ENGINE=MyISAM DEFAULT CHARSET=latin1

