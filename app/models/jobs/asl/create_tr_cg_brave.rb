module CreateTrCgBrave
  #tr_params = { candidate_path: '', #glob pattern to match
  #  image_category: '', #describe file
  #  tracker_id: '', 
  #  subject: '', #<subject> dir inside of asl/output/<protocol>/<subject>
  #  enrollment_id: '', #Enrollment table's id 
  #  sp_id: '', #ScanProcedure table's id
  #  new_table: ''} #new cg_asl table
  require 'csv'

  def create_tr_cg_brave(tr_params)
    harvest_log = ""
    return_hash = {:status => "", :path => "", :log => "", :job_log => [], :exclusions => []}
    tr_candidates = Dir.glob("#{tr_params[:candidate_path]}")
    if tr_candidates.length == 1
      tr_path = tr_candidates.first
      #Is there a QC Tracker for this object?
      existing_tracked_image = Processedimage.where("file_path like ?","%#{tr_path}%")
      if existing_tracked_image.count > 0
        cur_path = existing_tracked_image.first.file_path
        #this file has been QC tracked, so if it's passed, we should add it to the searchable table
        #self.log << {:message => "#{cur_path} already tracked. Searching Trfileimage for QC grade..."}
       # return_hash[:job_log] << {:message => "#{cur_path} already tracked. Searching Trfileimage for QC grade..."}
        return_hash[:job_log] << "#{cur_path} already tracked. Searching Trfileimage for QC grade..."
        harvest_log << "CreateTrCg: #{cur_path} already tracked. Searching Trfileimage for QC grade...\n"
        tracker = Trfileimage.where(:image_id => existing_tracked_image.first.id, :image_category => "#{tr_params[:image_category]}")
        #check if trfileimage exists for this processedimage
        if !tracker.empty?
          qc_val = tracker.first.trfile.qc_value
        else #!tracker.empty?
          #ProcessedImage but not TrFileImage
          #self.log << {:message => "#{tr_path} not found in Trfileimage. Creating tracking entries in Trfile, Trfileimage, and Tredit..."}
          #return_hash[:job_log] << {:message => "#{tr_path} not found in Trfileimage. Creating tracking entries in Trfile, Trfileimage, and Tredit..."}
          return_hash[:job_log] << "#{tr_path} not found in Trfileimage. Creating tracking entries in Trfile, Trfileimage, and Tredit..."
          harvest_log << "CreateTrCg: #{tr_path} not found in Trfileimage. Creating tracking entries in Trfile, Trfileimage, and Tredit...\n"
          image = existing_tracked_image.first
          #then create a trfile and add the images to it.
          trfiles = Trfile.where("trtype_id in (?)",tr_params[:tracker_id]).where("subjectid in (?)",tr_params[:subject])
          if trfiles.count == 0
            trfile = Trfile.new
            trfile.subjectid = tr_params[:subject]
            trfile.enrollment_id = tr_params[:enrollment_id]
            trfile.scan_procedure_id = tr_params[:sp_id]
            trfile.trtype_id = tr_params[:tracker_id]
            trfile.qc_value = "New Record"
            trfile.save
            #self.log << {:message => "#{tr_path} successfully added to Trfile..."}
            #return_hash[:job_log] << {:message => "#{tr_path} successfully added to Trfile..."}
            return_hash[:job_log] << "#{tr_path} successfully added to Trfile..."
            harvest_log << "CreateTrCg: #{tr_path} successfully added to Trfile...\n"
          else
            #self.log << {:message => "#{tr_path} already found in Trfile. Moving on..."}
            #return_hash[:job_log] << {:message => "#{tr_path} already found in Trfile. Moving on..."}
            return_hash[:job_log] << "#{tr_path} already found in Trfile. Moving on..."
            harvest_log << "CreateTrCg: #{tr_path} already found in Trfile. Moving on...\n"
            trfile = trfiles.first
          end
          #Create Trfileimage entry
          trimgs = Trfileimage.where("trfile_id in (?)",trfile.id).where("image_id in (?)",image.id)
          if trimgs.count == 0   
            trimg = Trfileimage.new
            trimg.trfile_id = trfile.id
            trimg.image_id = image.id
            trimg.image_category = "#{tr_params[:image_category]}"
            trimg.save
            #self.log << {:message => "#{tr_path} successfully added to Trfileimage..."}
            #return_hash[:job_log] << {:message => "#{tr_path} successfully added to Trfileimage..."}
            return_hash[:job_log] << "#{tr_path} successfully added to Trfileimage..."
            harvest_log << "CreateTrCg: #{tr_path} successfully added to Trfileimage...\n"
          else
            #self.log << {:message => "#{tr_path} already found in Trfileimage. Moving on..."}
            #return_hash[:job_log] << {:message => "#{tr_path} already found in Trfileimage. Moving on..."}
            return_hash[:job_log] << "#{tr_path} already found in Trfileimage. Moving on..."
            harvest_log << "CreateTrCg: #{tr_path} already found in Trfileimage. Moving on...\n"
            trimg = trimgs.first
          end
          #Create Tredit entry
          tredits = Tredit.where("trfile_id in (?)",trfile.id)
          if tredits.count == 0
            tredit = Tredit.new
            tredit.trfile_id = trfile.id
            tredit.save
            #self.log << {:message => "#{tr_path} successfully added to Tredit..."} 
            #return_hash[:job_log] << {:message => "#{tr_path} successfully added to Tredit..."}
            return_hash[:job_log] << "#{tr_path} successfully added to Tredit..." 
            harvest_log << "CreateTrCg: #{tr_path} successfully added to Tredit...\n"
          else
            #self.log << {:message => "#{tr_path} already found in Tredit. Moving on..."}
            #return_hash[:job_log] << {:message => "#{tr_path} already found in Tredit. Moving on..."}
            return_hash[:job_log] << "#{tr_path} already found in Tredit. Moving on..."
            harvest_log << "CreateTrCg: #{tr_path} already found in Tredit. Moving on...\n"
            tredit = tredits.first
          end
          #Set up the fields on this file
          qc_fields = Tractiontype.where("trtype_id in (?)",tr_params[:tracker_id])
          if qc_fields.count > 0
            qc_fields.each do |field|
              rating = TreditAction.new
              rating.tredit_id = tredit.id
              rating.tractiontype_id = field.id
              if !(field.form_default_value).blank?
                rating.value = field.form_default_value
              end
              rating.save
            end
          end
        end #!tracker.empty?
        #self.log << {:message => "#{tr_path} successfully tracked."}
        #return_hash[:job_log] << {:message => "#{tr_path} successfully tracked."}
        return_hash[:job_log] << "#{tr_path} successfully tracked."
        harvest_log << "CreateTrCg: #{tr_path} successfully tracked.\n"
        return_hash[:status] = "track_success"
        return_hash[:path] = tr_path
        return_hash[:log] = harvest_log
        return return_hash
      else #existing_tracked_image.count > 0
        #this file isn't tracked yet, so let's start tracking it
        image = Processedimage.new
        image.file_type = tr_params[:image_category]
        image.file_name = tr_candidates.first
        image.file_path = tr_candidates.first
        image.scan_procedure_id = tr_params[:sp_id]
        image.enrollment_id = tr_params[:enrollment_id]
        image.save
        #self.log << {:message => "#{tr_path} successfully added to Processedimage..."}
        #return_hash[:job_log] << {:message => "#{tr_path} successfully added to Processedimage..."}
        return_hash[:job_log] << "#{tr_path} successfully added to Processedimage..."
        harvest_log << "CreateTrCg: #{tr_path} successfully added to Processedimage...\n"
        #then create a trfile and add the images to it.
        trfiles = Trfile.where("trtype_id in (?)",tr_params[:tracker_id]).where("subjectid in (?)",tr_params[:subject])
        if trfiles.count == 0
          trfile = Trfile.new
          trfile.subjectid = tr_params[:subject]
          trfile.enrollment_id = tr_params[:enrollment_id]
          trfile.scan_procedure_id = tr_params[:sp_id]
          trfile.trtype_id = tr_params[:tracker_id]
          trfile.qc_value = "New Record"
          trfile.save
          #self.log << {:message => "#{tr_path} successfully added to Trfile..."}
          #return_hash[:job_log] << {:message => "#{tr_path} successfully added to Trfile..."}
          return_hash[:job_log] << "#{tr_path} successfully added to Trfile..."
          harvest_log << "CreateTrCg: #{tr_path} successfully added to Trfile...\n"
        else
          #self.log << {:message => "#{tr_path} already found in Trfile. Moving on..."}
          #return_hash[:job_log] << {:message => "#{tr_path} already found in Trfile. Moving on..."}
          return_hash[:job_log] << "#{tr_path} already found in Trfile. Moving on..."
          harvest_log << "CreateTrCg: #{tr_path} already found in Trfile. Moving on...\n"
          trfile = trfiles.first
        end
        #Create Trfileimage entry
        trimgs = Trfileimage.where("trfile_id in (?)",trfile.id).where("image_id in (?)",image.id)
        if trimgs.count == 0
          trimg = Trfileimage.new
          trimg.trfile_id = trfile.id
          trimg.image_id = image.id
          trimg.image_category = tr_params[:image_category]
          trimg.save
          #self.log << {:message => "#{tr_path} successfully added to Trfileimage..."}
          #return_hash[:job_log] << {:message => "#{tr_path} successfully added to Trfileimage..."}
          return_hash[:job_log] << "#{tr_path} successfully added to Trfileimage..."
          harvest_log << "CreateTrCg: #{tr_path} successfully added to Trfileimage...\n"
        else
          #self.log << {:message => "#{tr_path} already found in Trfileimage. Moving on..."}
          #return_hash[:job_log] << {:message => "#{tr_path} already found in Trfileimage. Moving on..."}
          return_hash[:job_log] << "#{tr_path} already found in Trfileimage. Moving on..."
          harvest_log << "CreateTrCg: #{tr_path} already found in Trfileimage. Moving on...\n"
          trimg = trimgs.first
        end
        #Create Tredit entry
        tredits = Tredit.where("trfile_id in (?)",trfile.id)
        if tredits.count != 1
          tredit = Tredit.new
          tredit.trfile_id = trfile.id
          tredit.save
          #self.log << {:message => "#{tr_path} successfully added to Tredit..."}
          #return_hash[:job_log] << {:message => "#{tr_path} successfully added to Tredit..."}
          return_hash[:job_log] << "#{tr_path} successfully added to Tredit..."
          harvest_log << "CreateTrCg: #{tr_path} successfully added to Tredit...\n"
        else
          #self.log << {:message => "#{tr_path} already found in Tredit. Moving on..."}
          #return_hash[:job_log] << {:message => "#{tr_path} already found in Tredit. Moving on..."}
          return_hash[:job_log] << "#{tr_path} already found in Tredit. Moving on..."
          harvest_log << "CreateTrCg: #{tr_path} already found in Tredit. Moving on...\n"
          tredit = tredits.first
        end
        #Set up the fields on this file
        qc_fields = Tractiontype.where("trtype_id in (?)",tr_params[:tracker_id])
        if qc_fields.count > 0
          qc_fields.each do |field|
            rating = TreditAction.new
            rating.tredit_id = tredit.id
            rating.tractiontype_id = field.id
            if !(field.form_default_value).blank?
              rating.value = field.form_default_value
            end
            rating.save
          end
        end

      end #existing_tracked_image.count > 0



      ###Check if cg_asl_brave entry for this trfile exists and create one if it does not
      pre_check_sql = "SELECT id FROM #{tr_params[:new_table]} WHERE scan_procedure_id = '#{tr_params[:sp_id]}' AND enrollment_id = '#{tr_params[:enrollment_id]}' AND trfile_id = '#{trfile.id}';"
      pre_check = @connection.execute(pre_check_sql)           
      if pre_check.count < 1 #Add to cg_asl

        path_parts = tr_params[:candidate_path].split('/')[0...-1]
        cbf_dir = path_parts.join('/') #split, drop last element, and join by file separator

        #Check if series number of cbf derived matches 3D ASL research scan's series number
        series_num = 999999 #Place holder in case glob returns nothing
        cbf_num = path_parts.last.split('_').last.first.to_i #get series number for CBF
        protocol = path_parts[-2]
        research_search = Dir.glob("/mounts/data/preprocessed/visits/#{protocol}/#{tr_params[:subject]}/unknown/#{tr_params[:subject]}_3D_ASL_research_*.nii")
        if !research_search.empty?
          series_num = research_search.first.split("_").last.split(".").first.to_i #series number for original asl research scan
        end
        if series_num == cbf_num
          research_cbf = true
        else
          research_cbf = false
        end

        neuro_path_glob = "#{cbf_dir}/mri/neuromorphometrics*.csv"
        neuro_paths = Dir.glob(neuro_path_glob)
        perf_path = "#{cbf_dir}/native_space_perfusion.json"
        if !neuro_paths.empty? && File.exist?(perf_path)
          neuro_path = neuro_paths.first
        else
          #self.exclusions << {:tr_candidates => "#{cur_path} NOT SUCCESSFULLY INSERTED INTO #{tr_params[:new_table]}"}
          #return_hash[:exclusions] << {:tr_candidates => "#{cur_path} NOT SUCCESSFULLY INSERTED INTO #{tr_params[:new_table]}. NEUROMORPHOMETRICS CSV MISSING FROM MRI OR NATIVE SPACE PERFUSION JSON MISSING!"}
          return_hash[:exclusions] << "#{cbf_dir} NOT SUCCESSFULLY INSERTED INTO #{tr_params[:new_table]}. NEUROMORPHOMETRICS CSV MISSING FROM MRI OR NATIVE SPACE PERFUSION JSON MISSING!"
          harvest_log << "CreateTrCg: #{cbf_dir} NOT SUCCESSFULLY INSERTED INTO #{tr_params[:new_table]}! NEUROMORPHOMETRICS CSV MISSING FROM MRI OR NATIVE SPACE PERFUSION JSON MISSING!\n"
          #Delete all other rows from this scan
          #del_sql = "DELETE FROM #{tr_params[:new_table]} WHERE protocol = #{tr_params[:sp_id]} AND subject_id = '#{tr_params[:subject]}}' AND reggie_id = '#{reggie_id}'"
          return_hash[:status] = "track_fail"
          return_hash[:path] = cbf_dir
          return_hash[:log] = harvest_log
          return return_hash
        end
        neuro_table = CSV.parse(File.read(neuro_path), headers: false)
        #neuro_hash = Hash[neuro_table[0].zip neuro_table[3]]
        #Check that we got the expected data/rows
        if !neuro_table[0][0].include?("id") || !neuro_table[3][0].include?("cg_mri")
          #self.exclusions << {:tr_candidates => "#{cur_path} NOT SUCCESSFULLY INSERTED INTO #{tr_params[:new_table]}"}
          #return_hash[:exclusions] << {:tr_candidates => "#{cur_path} NOT SUCCESSFULLY INSERTED INTO #{tr_params[:new_table]}. NEUROMORPHOMETRICS CSV NOT FORMATTED AS EXPECTED!"}
          return_hash[:exclusions] << "#{cbf_dir} NOT SUCCESSFULLY INSERTED INTO #{tr_params[:new_table]}. NEUROMORPHOMETRICS CSV NOT FORMATTED AS EXPECTED!"
          harvest_log << "CreateTrCg: #{cbf_dir} NOT SUCCESSFULLY INSERTED INTO #{tr_params[:new_table]}! NEUROMORPHOMETRICS CSV NOT FORMATTED AS EXPECTED!\n"
          #Delete all other rows from this scan
          #del_sql = "DELETE FROM #{tr_params[:new_table]} WHERE protocol = #{tr_params[:sp_id]} AND subject_id = '#{tr_params[:subject]}}' AND reggie_id = '#{reggie_id}'"
          return_hash[:status] = "track_fail"
          return_hash[:path] = cbf_dir
          return_hash[:log] = harvest_log
          return return_hash
        end
        #Insert each value into neuromorph_metrics table
        #has '' around column names #column_names = "scan_procedure_id, enrollment_id, participant_id, trfile_id, processed_image_id, neuromorph_cbf_metrics_id, neuromorph_vgm_metrics_id, #{neuro_table[1].map { |s| "'#{s.downcase.tr(" ", "_")}'"}.join(', ')}" #downcase all ROI names, replace spaces with _, and then seperate by comma and space for MySQL syntax
#        roi_names = "#{neuro_table[1][1...].map { |s| s.downcase.tr(' ', '_')}.join('`, `')}" #downcase all ROI names, replace spaces with _, and then seperate by comma and space for MySQL syntax #skip first column because that is "ROIname"
#        column_names = "cg_asl_id, #{roi_names}"
        column_names = "`cg_asl_id`"
        #neuro_table[1][1...].each { |name| column_names << ",`#{name.downcase.tr(" ","_")}`" }
        #CBF
        #cbf_values = neuro_table[3][1...].map { |s| s.to_f }.each { |val| val.join(`', '`) }
        #cbf_values = neuro_table[3][1...].join(', ')
        cbf_values.gsub!("NaN", "NULL")
        #VGM
        #vgm_values = neuro_table[2][1...].map { |s| s.to_i }.each { |val| val.join(`', '`) }
        #vgm_values = neuro_table[2][1...].join(', ')
        vgm_values.gsub!("NaN", "NULL")
        #ASL
        asl_column_names = "scan_procedure_id, enrollment_id, participant_id, trfile_id, processed_image_id, neuromorph_cbf_metrics_id, neuromorph_vgm_metrics_id, research_cbf, gm_cbf_median, gm_cbf_mad, gm_cbf_mean, gm_cbf_std, wm_cbf_median, wm_cbf_mad, wm_cbf_mean, wm_cbf_std"
        #Get native space perfusion stats
        pt_id = Enrollment.where(:id => tr_params[:enrollment_id]).first.participant_id
        #tr_id = Trfile.where("trtype_id in (?)",tr_params[:tracker_id]).where("subjectid in (?)",tr_params[:subject]).first.id
        primg_id = Processedimage.where("file_path like ?","%#{tr_candidates.first}%").first.id
        perf_stats = JSON.parse(File.read(perf_path))
        asl_values = "#{tr_params[:sp_id]}, #{tr_params[:enrollment_id]}, #{pt_id} , #{trfile.id}, #{primg_id}, 999, 111, #{research_cbf}, #{perf_stats['gm_cbf_median']}, #{perf_stats['gm_cbf_mad']}, #{perf_stats['gm_cbf_mean']}, #{perf_stats['gm_cbf_std']}, #{perf_stats['wm_cbf_median']}, #{perf_stats['wm_cbf_mad']}, #{perf_stats['wm_cbf_mean']}, #{perf_stats['wm_cbf_std']}"
        asl_insert = "INSERT INTO #{tr_params[:new_table]} (#{asl_column_names}) values (#{asl_values});"
        if asl_values.include?("nil")
          asl_out = asl_column_names.split(', ').zip(asl_values.split(', '))
          harvest_log << "CreateTrCG: NIL VALUES ENTERED INTO CG_ASL_BRAVE! #{cbf_dir} MISSING VALUES: #{asl_out}"
        end
        ActiveRecord::Base.connection.execute(asl_insert)
        cg_check = "SELECT id FROM #{tr_params[:new_table]} WHERE neuromorph_cbf_metrics_id = 999 AND neuromorph_vgm_metrics_id = 111;"
        asl_id_out = ActiveRecord::Base.connection.execute(cg_check)
        if asl_id_out.count < 1
          #return_hash[:exclusions] << {:tr_candidates => "#{cur_path} NOT SUCCESSFULLY INSERTED INTO #{tr_params[:new_table]}. Could not find entry in cg_asl_brave! cbf_id = 999 and vgm_id = 111."}
          return_hash[:exclusions] << "#{cbf_dir} NOT SUCCESSFULLY INSERTED INTO #{tr_params[:new_table]}. Could not find entry in cg_asl_brave! cbf_id = 999 and vgm_id = 111."
          harvest_log << "CreateTrCg: #{cbf_dir} NOT SUCCESSFULLY INSERTED INTO #{tr_params[:new_table]}! Could not find entry in cg_asl_brave! cbf_id = 999 and vgm_id = 111.\n"
          return_hash[:status] = "track_fail"
          return_hash[:path] = cbf_dir
          return_hash[:log] = harvest_log
          return return_hash
        else
          asl_id = asl_id_out.first.first
        end
        
        
        #Create CBF and VGM with cg_asl_id
        cbf_insert = "INSERT INTO neuromorph_cbf_metrics (#{column_names}) values (#{asl_id}, #{cbf_values});"
        ActiveRecord::Base.connection.execute(cbf_insert)
        vgm_insert = "INSERT INTO neuromorph_vgm_metrics (#{column_names}) values (#{asl_id}, #{vgm_values});"
        ActiveRecord::Base.connection.execute(vgm_insert)
        #Update cg_asl with neuromorph IDs
        cbf_check = "SELECT id FROM neuromorph_cbf_metrics WHERE cg_asl_id = #{asl_id};"
        cbf_id_out = ActiveRecord::Base.connection.execute(cbf_check)
        if cbf_id_out.count < 1
          #return_hash[:exclusions] << {:tr_candidates => "#{cur_path} NOT SUCCESSFULLY INSERTED INTO #{tr_params[:new_table]}. Could not find entry in neuromorph_cbf_metrics! cg_asl_id = #{asl_id}."}
          return_hash[:exclusions] << "#{cbf_dir} NOT SUCCESSFULLY INSERTED INTO #{tr_params[:new_table]}. Could not find entry in neuromorph_cbf_metrics! cg_asl_id = #{asl_id}."
          harvest_log << "CreateTrCg: #{cbf_dir} NOT SUCCESSFULLY INSERTED INTO #{tr_params[:new_table]}! Could not find entry in neuromorph_cbf_metrics! cg_asl_id = #{asl_id}.\n"
          return_hash[:status] = "track_fail"
          return_hash[:path] = cbf_dir
          return_hash[:log] = harvest_log
          return return_hash
        else
          cbf_id = cbf_id_out.first.first
        end
        vgm_check = "SELECT id FROM neuromorph_vgm_metrics WHERE cg_asl_id = #{asl_id};"
        vgm_id_out = ActiveRecord::Base.connection.execute(vgm_check)
        if vgm_id_out.count < 1
          #return_hash[:exclusions] << {:tr_candidates => "#{cur_path} NOT SUCCESSFULLY INSERTED INTO #{tr_params[:new_table]}. Could not find entry in neuromorph_vgm_metrics! cg_asl_id = #{asl_id}."}
          return_hash[:exclusions] << "#{cbf_dir} NOT SUCCESSFULLY INSERTED INTO #{tr_params[:new_table]}. Could not find entry in neuromorph_vgm_metrics! cg_asl_id = #{asl_id}."
          harvest_log << "CreateTrCg: #{cbf_dir} NOT SUCCESSFULLY INSERTED INTO #{tr_params[:new_table]}! Could not find entry in neuromorph_vgm_metrics! cg_asl_id = #{asl_id}.\n"
          return_hash[:status] = "track_fail"
          return_hash[:path] = cbf_dir
          return_hash[:log] = harvest_log
          return return_hash
        else
          vgm_id = vgm_id_out.first.first
        end
        update_cg = "UPDATE #{tr_params[:new_table]} SET neuromorph_cbf_metrics_id = #{cbf_id}, neuromorph_vgm_metrics_id = #{vgm_id} WHERE id = #{asl_id};"
        ActiveRecord::Base.connection.execute(update_cg)

        #self.exclusions << {:tr_candidates => "#{cur_path} NOT SUCCESSFULLY INSERTED INTO #{tr_params[:new_table]}"}
        #return_hash[:exclusions] << {:tr_candidates => "#{cur_path} NOT SUCCESSFULLY INSERTED INTO #{tr_params[:new_table]}"}
        return_hash[:exclusions] << "#{cbf_dir} NOT SUCCESSFULLY INSERTED INTO #{tr_params[:new_table]}"
        harvest_log << "CreateTrCg: #{cbf_dir} NOT SUCCESSFULLY INSERTED INTO #{tr_params[:new_table]}!\n"
        #Delete all other rows from this scan
        #del_sql = "DELETE FROM #{tr_params[:new_table]} WHERE protocol = #{tr_params[:sp_id]} AND subject_id = '#{tr_params[:subject]}}' AND reggie_id = '#{reggie_id}'"
        return_hash[:status] = "track_fail"
        return_hash[:path] = cbf_dir
        return_hash[:log] = harvest_log
        return return_hash
      elsif pre_check.count > 1
        #self.exclusions << {:tr_candidates => "#{cur_path} HAS MULTIPLE ENTRIES IN #{tr_params[:new_table]}. NOT INSERTING!"}
        #return_hash[:exclusions] << {:tr_candidates => "#{cur_path} HAS MULTIPLE ENTRIES IN #{tr_params[:new_table]}. NOT INSERTING!"}
        return_hash[:exclusions] << "#{cbf_dir} HAS MULTIPLE ENTRIES IN #{tr_params[:new_table]}. NOT INSERTING!"
        harvest_log << "CreateTrCg: #{cbf_dir} HAS MULTIPLE ENTRIES IN #{tr_params[:new_table]}. NOT INSERTING!\n"
        #Delete all other rows from this scan
        #del_sql = "DELETE FROM #{tr_params[:new_table]} WHERE protocol = #{tr_params[:sp_id]} AND subject_id = '#{tr_params[:subject]}}' AND reggie_id = '#{reggie_id}'"
        return_hash[:status] = "track_fail"
        return_hash[:path] = cbf_dir
        return_hash[:log] = harvest_log
        return return_hash
      elsif pre_check.count == 1
        #self.log << {:message => "#{cur_path} successfully added to #{tr_params[:new_table]}..."}
        #return_hash[:job_log] << {:message => "#{cur_path} already in #{tr_params[:new_table]}..."}
        return_hash[:job_log] << "#{cbf_dir} already in #{tr_params[:new_table]}..."
        harvest_log << "CreateTrCg: #{cbf_dir} already in #{tr_params[:new_table]}...\n"
        return_hash[:status] = "track_success"
        return_hash[:path] = cbf_dir
        return_hash[:log] = harvest_log
        return return_hash
      end

      #      end #existing_tracked_image.count > 0
      #self.log << {:message => "#{tr_path} successfully tracked."}
      #return_hash[:job_log] << {:message => "#{tr_path} successfuLly tracked."}
      return_hash[:job_log] << "#{tr_path} successfully tracked."
      harvest_log << "CreateTrCg: #{tr_path} successfully tracked.\n"
      return_hash[:status] = "track_success"
      return_hash[:path] = tr_path
      return_hash[:log] = harvest_log
      return return_hash
    elsif tr_candidates.length == 0 #tr_candidates.length == 1
      #self.exclusions << {:tr_candidates => "NO #{tr_params[:image_category]} FOUND for #{tr_params[:candidate_path]}"}
      #return_hash[:exclusions] << {:tr_candidates => "NO #{tr_params[:image_category]} FOUND for #{tr_params[:candidate_path]}"}
      return_hash[:exclusions] << "NO #{tr_params[:image_category]} FOUND for #{tr_params[:candidate_path]}"
      harvest_log << "CreateTrCg: NO #{tr_params[:image_category]} FOUND for #{tr_params[:candidate_path]}\n"
      #Delete all other rows from this scan
      #del_sql = "DELETE FROM #{tr_params[:new_table]} WHERE protocol = #{tr_params[:sp_id]} AND subject_id = '#{tr_params[:subject]}}' AND reggie_id = '#{reggie_id}'"
      return_hash[:status] = "track_fail"
      return_hash[:path] = tr_path
      return_hash[:log] = harvest_log
      return return_hash
    else #tr_candidates.length not 1 or 0
      #weirdness. Too many products? Also log this.
      #self.exclusions << {:tr_candidates => "TOO MANY #{tr_params[:image_category]} FOUND for #{tr_params[:candidate_path]}"}
      #return_hash[:exclusions] << {:tr_candidates => "TOO MANY #{tr_params[:image_category]} FOUND for #{tr_params[:candidate_path]}"}
      return_hash[:exclusions] << "TOO MANY #{tr_params[:image_category]} FOUND for #{tr_params[:candidate_path]}"
      harvest_log << "CreateTrCg: TOO MANY #{tr_params[:image_category]} FOUND for #{tr_params[:candidate_path]}.\n"
      #Delete all other rows from this scan
      #del_sql = "DELETE FROM #{tr_params[:new_table]} WHERE protocol = #{tr_params[:sp_id]} AND subject_id = '#{tr_params[:subject]}}' AND reggie_id = '#{reggie_id}'"
      return_hash[:status] = "track_fail"
      return_hash[:path] = tr_path
      return_hash[:log] = harvest_log
      return return_hash
    end #tr_candidates.length == 1
  end #create_trfile(tr_params)
end
