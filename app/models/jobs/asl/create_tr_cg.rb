module CreateTrCg
  #tr_params = { candidate_path: '', #glob pattern to match
  #  image_category: '', #describe file
  #  tracker_id: '', 
  #  subject: '', #<subject> dir inside of asl/output/<protocol>/<subject>
  #  enrollment_id: '', #Enrollment table's id 
  #  sp_id: '', #ScanProcedure table's id
  #  new_table: ''} #new cg_asl table

  def create_tr_cg(tr_params)
    harvest_log = ""
    return_hash = {:status => "", :path => "", :log => ""}
    tr_candidates = Dir.glob("#{tr_params[:candidate_path]}")
    if tr_candidates.length == 1
      tr_path = "#{tr_candidates.first}"
      #Is there a QC Tracker for this object?
      existing_tracked_image = Processedimage.where("file_path like ?","%#{tr_path}%")
      if existing_tracked_image.count > 0
        cur_path = existing_tracked_image.first.file_path
        #this file has been QC tracked, so if it's passed, we should add it to the searchable table
        self.log << {:message => "#{cur_path} already tracked. Searching Trfileimage for QC grade..."}
        harvest_log << "CreateTrCg: #{cur_path} already tracked. Searching Trfileimage for QC grade...\n"
        tracker = Trfileimage.where(:image_id => existing_tracked_image.first.id, :image_category => "#{tr_params[:image_category]}")
        #check if trfileimage exists for this processedimage
        if !tracker.empty?
          qc_val = tracker.first.trfile.qc_value
          #Get reggie_id through Enrollment => Participant for table entry
          reggie_id = Enrollment.where(:id => tr_params[:enrollment_id]).first.participant.reggieid
          if reggie_id.blank?
            self.error_log << {:message => "#{cur_path}: #{tracker.first.image_id} not found in Enrollment Table!"}
            harvest_log << "CreateTrCg: #{cur_path}: #{tracker.first.image_id} not found in Enrollment Table!\n"
           # harvest_log << "CreateTrCg: #{cur_path}: #{tracker.first.image_id} not found in ImageDataset Table!\nDELETE: All #{tr_params[:new_table]} entries for #{tr_params[:subject]} deleted!"
            #Delete all other rows from this scan
           # del_sql = "DELETE FROM #{tr_params[:new_table]} WHERE protocol = #{tr_params[:sp_id]} AND subject_id = '#{tr_params[:subject]}}' AND reggie_id = '#{reggie_id}'"
            return_hash[:status] = "track_fail"
            return_hash[:path] = cur_path
            return_hash[:log] = harvest_log
            return return_hash
          else
            reggie_id = Enrollment.where(:id => tr_params[:enrollment_id]).first.participant.reggieid
            harvest_log << "CreateTrCg: Reggie_ID: #{reggie_id} found for #{cur_path}.\n"
          end
          #If passed QC then insert into new table
          if qc_val == 'Pass'
            self.log << {:message => "#{cur_path} passed QC. Adding to #{tr_params[:new_table]}..."} 
            harvest_log << "CreateTrCg: #{cur_path} passed QC. Adding to #{tr_params[:new_table]}...\n"
            insert_sql = "INSERT INTO #{tr_params[:new_table]} (protocol, subject_id, reggie_id, file_type) values ('#{tr_params[:sp_id]}','#{tr_params[:subject]}','#{reggie_id}', '#{tr_params[:image_category]}');"
            @connection.execute(insert_sql) #ActiveRecord::Base.connection()
            check_sql = "SELECT id FROM #{tr_params[:new_table]} WHERE protocol = '#{tr_params[:sp_id]}' AND subject_id = '#{tr_params[:subject]}' AND reggie_id = '#{reggie_id}' AND file_type = '#{tr_params[:image_category]}';"
            check = @connection.execute(check_sql)           
            if check.count < 1
              self.exclusions << {:tr_candidates => "#{cur_path} NOT SUCCESSFULLY INSERTED INTO #{tr_params[:new_table]}"}
              harvest_log << "CreateTrCg: #{cur_path} NOT SUCCESSFULLY INSERTED INTO #{tr_params[:new_table]}!\n"
              #Delete all other rows from this scan
              #del_sql = "DELETE FROM #{tr_params[:new_table]} WHERE protocol = #{tr_params[:sp_id]} AND subject_id = '#{tr_params[:subject]}}' AND reggie_id = '#{reggie_id}'"
              return_hash[:status] = "track_fail"
              return_hash[:path] = cur_path
              return_hash[:log] = harvest_log
              return return_hash
            elsif check.count > 1
              self.exclusions << {:tr_candidates => "#{cur_path} HAS MULTIPLE ENTRIES IN #{tr_params[:new_table]}. NOT INSERTING!"}
              harvest_log << "CreateTrCg: #{cur_path} HAS MULTIPLE ENTRIES IN #{tr_params[:new_table]}. NOT INSERTING!\n"
              #Delete all other rows from this scan
              #del_sql = "DELETE FROM #{tr_params[:new_table]} WHERE protocol = #{tr_params[:sp_id]} AND subject_id = '#{tr_params[:subject]}}' AND reggie_id = '#{reggie_id}'"
              return_hash[:status] = "track_fail"
              return_hash[:path] = cur_path
              return_hash[:log] = harvest_log
              return return_hash
            elsif check.count == 1
              self.log << {:message => "#{cur_path} successfully added to #{tr_params[:new_table]}..."}
              harvest_log << "CreateTrCg: #{cur_path} successfully added to #{tr_params[:new_table]}...\n"
              return_hash[:status] = "track_success"
              return_hash[:path] = cur_path
              return_hash[:log] = harvest_log
              return return_hash
            end
          elsif qc_val == 'New Record'
            self.exclusions << {:tr_candidates => "#{cur_path} NEEDS QC YET."}
            harvest_log << "CreateTrCg: #{cur_path} NEEDS QC YET..\n"
            return_hash[:status] = "needs_qc"
            return_hash[:path] = cur_path
            return_hash[:log] = harvest_log
            return return_hash
          else
            self.exclusions << {:tr_candidates => "#{cur_path} FAILED QC. QC_STATUS: #{qc_val}."}
            harvest_log << "CreateTrCg: #{cur_path} FAILED QC. QC_STATUS: #{qc_val}.\nDELETE: All #{tr_params[:new_table]} entries for #{tr_params[:subject]} deleted!"
            #Delete all other rows from this scan
            #del_sql = "DELETE FROM #{tr_params[:new_table]} WHERE protocol = #{tr_params[:sp_id]} AND subject_id = '#{tr_params[:subject]}}' AND reggie_id = '#{reggie_id}'"
            return_hash[:status] = "qc_fail"
            return_hash[:path] = cur_path
            return_hash[:log] = harvest_log
            return return_hash
          end
        else #!tracker.empty?
          #ProcessedImage but not TrFileImage
          self.log << {:message => "#{tr_path} not found in Trfileimage. Creating tracking entries in Trfile, Trfileimage, and Tredit..."}
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
            self.log << {:message => "#{tr_path} successfully added to Trfile..."}
            harvest_log << "CreateTrCg: #{tr_path} successfully added to Trfile...\n"
          else
            self.log << {:message => "#{tr_path} already found in Trfile. Moving on..."}
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
            self.log << {:message => "#{tr_path} successfully added to Trfileimage..."}
            harvest_log << "CreateTrCg: #{tr_path} successfully added to Trfileimage...\n"
          else
            self.log << {:message => "#{tr_path} already found in Trfileimage. Moving on..."}
            harvest_log << "CreateTrCg: #{tr_path} already found in Trfileimage. Moving on...\n"
            trimg = trimgs.first
          end
          #Create Tredit entry
          tredits = Tredit.where("trfile_id in (?)",trfile.id)
          if tredits.count == 0
            tredit = Tredit.new
            tredit.trfile_id = trfile.id
            tredit.save
            self.log << {:message => "#{tr_path} successfully added to Tredit..."} 
            harvest_log << "CreateTrCg: #{tr_path} successfully added to Tredit...\n"
          else
            self.log << {:message => "#{tr_path} already found in Tredit. Moving on..."}
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
        self.log << {:message => "#{tr_path} successfully tracked."}
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
        self.log << {:message => "#{tr_path} successfully added to Processedimage..."}
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
          self.log << {:message => "#{tr_path} successfully added to Trfile..."}
          harvest_log << "CreateTrCg: #{tr_path} successfully added to Trfile...\n"
        else
          self.log << {:message => "#{tr_path} already found in Trfile. Moving on..."}
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
          self.log << {:message => "#{tr_path} successfully added to Trfileimage..."}
          harvest_log << "CreateTrCg: #{tr_path} successfully added to Trfileimage...\n"
        else
          self.log << {:message => "#{tr_path} already found in Trfileimage. Moving on..."}
          harvest_log << "CreateTrCg: #{tr_path} already found in Trfileimage. Moving on...\n"
          trimg = trimgs.first
        end
        #Create Tredit entry
        tredits = Tredit.where("trfile_id in (?)",trfile.id)
        if tredits.count == 0
          tredit = Tredit.new
          tredit.trfile_id = trfile.id
          tredit.save
          self.log << {:message => "#{tr_path} successfully added to Tredit..."}
          harvest_log << "CreateTrCg: #{tr_path} successfully added to Tredit...\n"
        else
          self.log << {:message => "#{tr_path} already found in Tredit. Moving on..."}
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
      self.log << {:message => "#{tr_path} successfully tracked."}
      harvest_log << "CreateTrCg: #{tr_path} successfully tracked.\n"
      return_hash[:status] = "track_success"
      return_hash[:path] = tr_path
      return_hash[:log] = harvest_log
      return return_hash
    elsif tr_candidates.length == 0 #tr_candidates.length == 1
      self.exclusions << {:tr_candidates => "NO #{tr_params[:image_category]} FOUND for #{tr_params[:candidate_path]}"}
      harvest_log << "CreateTrCg: NO #{tr_params[:image_category]} FOUND for #{tr_params[:candidate_path]}\n"
      #Delete all other rows from this scan
      #del_sql = "DELETE FROM #{tr_params[:new_table]} WHERE protocol = #{tr_params[:sp_id]} AND subject_id = '#{tr_params[:subject]}}' AND reggie_id = '#{reggie_id}'"
      return_hash[:status] = "track_fail"
      return_hash[:path] = tr_path
      return_hash[:log] = harvest_log
      return return_hash
    else #tr_candidates.length not 1 or 0
      #weirdness. Too many products? Also log this.
      self.exclusions << {:tr_candidates => "TOO MANY #{tr_params[:image_category]} FOUND for #{tr_params[:candidate_path]}"}
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
