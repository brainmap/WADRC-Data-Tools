class Jobs::Lst::AdcpDriver < Jobs::Lst::LstLpaDriver

  attr_accessor :ok_paths_and_not_processed_before
  attr_accessor :total_scans_considered
  attr_accessor :selected
  attr_accessor :driver

  def self.default_params
    params = { schedule_name: 'LST/LPA Pipeline Driver, ADCP',
                base_path: "/mounts/data", 
                computer: "kanga",
                dry_run: false,
                run_by_user: 'panda_user',
                code_ver: '20ae61c',
                exclude_sp_mri_array: [-1,100,76,78],
                include_sp_mri_array: [80,115],
                date_cutoff: '2018-10-11',
                csv_headers: ['scan_procedure','enrollment','ACPC_T1_path','T2_FLAIR', 'FLAIR_incomplete_series',
                        'FLAIR_garbled_series_comment','FLAIR_garbled_series','FLAIR_garbled_series_comment',
                        'FLAIR_fov_cutoff', 'FLAIR_fov_cutoff_comment', 'FLAIR_field_inhomogeneity','FLAIR_field_inhomogeneity_comment',
                        'FLAIR_ghosting_wrapping', 'FLAIR_ghosting_wrapping_comment', 'FLAIR_banding','FLAIR_banding_comment',
                        'FLAIR_registration_risk', 'FLAIR_registration_risk_comment', 'FLAIR_motion_warning', 'FLAIR_motion_warning_comment',
                        'FLAIR_omnibus_f', 'FLAIR_omnibus_f_comment', 'FLAIR_spm_mask','FLAIR_spm_mask_comment', 'FLAIR_nos_concerns',
                        'FLAIR_nos_concerns_comment','FLAIR_other_issues'],
                driver_path: "/mounts/data/analyses/wbbevis/lst_lpa/",
                driver_file_name: "#{Date.today.strftime("%Y-%m-%d")}_lst_lpa_driver_ADCP.csv",
                processing_output_path: "/mounts/data/development/lstlpa/output",
                processing_input_path: "/mounts/data/development/lstlpa/input",
                processing_executable_path: "/mounts/data/development/lstlpa/src/run_lpa.sh",
              }
    params.default = ''
    params
  end

  def self.production_params
    params = { schedule_name: 'LST/LPA Pipeline Driver, ADCP',
                base_path: "/mounts/data", 
                computer: "moana",
                dry_run: false,
                run_by_user: 'panda_user',
                code_ver: 'd0fc77a9',
                exclude_sp_mri_array: [-1,100,76,78],
                include_sp_mri_array: [80,115],
                date_cutoff: '2015-06-01',
                csv_headers: ['scan_procedure','enrollment','ACPC_T1_path','T2_FLAIR', 'FLAIR_incomplete_series',
                        'FLAIR_garbled_series_comment','FLAIR_garbled_series','FLAIR_garbled_series_comment',
                        'FLAIR_fov_cutoff', 'FLAIR_fov_cutoff_comment', 'FLAIR_field_inhomogeneity','FLAIR_field_inhomogeneity_comment',
                        'FLAIR_ghosting_wrapping', 'FLAIR_ghosting_wrapping_comment', 'FLAIR_banding','FLAIR_banding_comment',
                        'FLAIR_registration_risk', 'FLAIR_registration_risk_comment', 'FLAIR_motion_warning', 'FLAIR_motion_warning_comment',
                        'FLAIR_omnibus_f', 'FLAIR_omnibus_f_comment', 'FLAIR_spm_mask','FLAIR_spm_mask_comment', 'FLAIR_nos_concerns',
                        'FLAIR_nos_concerns_comment','FLAIR_other_issues'],
                driver_path: "/mounts/data/analyses/wbbevis/lst_lpa/",
                driver_file_name: "#{Date.today.strftime("%Y-%m-%d")}_lst_lpa_driver_ADCP.csv",
                processing_output_path: "/mounts/data/pipelines/lstlpa/output",
                processing_input_path: "/mounts/data/pipelines/lstlpa/input",
                processing_executable_path: "/mounts/data/pipelines/lstlpa/src/run_lpa.sh",
              }
    params.default = ''
    params
  end

  def setup(params)

      @total_scans_considered = 0
      @ok_paths_and_not_processed_before = []
      @driver = []
      @selected = {}

  end

  def selection(params)
    # 2020-12-15 wbbevis - ADCP works differently from the other protocols. They spread out the MRI scan into 
    # two different visits, both with the same protocol codename & some overlapping enrollment numbers, but
    # on different dates. Under most other circumstances, we do just one MR visit per protocol visit. So, 
    # at this stage, we need to group the visits by scan_proc/enumber, then vet them as a group. 

    # first get the participants
    all_adcp_ppts = Enrollment.where("enumber like 'adcp%'").map(&:participant_id).uniq.compact
    all_adcp_enrollment_groups = all_adcp_ppts.map{|item| Enrollment.where(:participant_id => item).where("enumber like 'adcp%'")}

    adcp_scan_procedures = ScanProcedure.where(:id => params[:include_sp_mri_array])

    all_adcp_enrollment_groups.each do |enrollments|
      enrollment_group = {}

      # this next line isn't super readable, but I'm getting vgroups from each enrollment where the vgroup's scan procedures 
      # and the overall list of ADCP whitelisted scan procedures have some overlap (i.e. the setwise intersection is not nil).
      vgroups = enrollments.map{|enr| enr.vgroups.select{|vg| !(vg.scan_procedures & adcp_scan_procedures).nil? }}.flatten.uniq
      scan_procedures = vgroups.map{|item| item.scan_procedures}.flatten.uniq
      scan_procedures.each do |sp|
        vgroup_subset = vgroups.select{|item| item.scan_procedures.include? sp}
        visits = vgroup_subset.map{|vg| vg.appointments.map{|appt| Visit.where(:appointment_id => appt.id)}}.flatten.uniq
        if visits.count > 0
          enrollment_group[sp.codename] = visits
        end
      end

      #let's just prevent empty cases here
      if enrollment_group.values.count > 0
        @selected[enrollments.first.participant_id] = enrollment_group
      end
    end


  end

  def filter(params)

    @selected.each do |ppt_id, visit_groups|

        visit_groups.each do |protocol, visits|

          @total_scans_considered += 1

          vgroups = visits.map{|visit| visit.appointment.vgroup}.flatten

          #first let's get the primary scan_procedure, and the enrollment

          scan_procedure = ScanProcedure.where(:codename => protocol).first
          if scan_procedure.nil?
            self.exclusions << {:protocol => protocol, :ppt_id => ppt_id, :message => "scan procedures broken for this visit group"}
            next
          end

          enrollments = Enrollment.where(:participant_id => ppt_id).where("enumber like 'adcp%'")

          # ADCP has multiple enrollment aliases. This has been used as a workaround for their multiple MR visits. 
          # Usually there's one in a group that doesn't have underscores, and for best consistency with the other
          # data we process in this pipeline, let's use the one without underscores.

          preferred_enumber_enrollment = enrollments.select{|enr| !(enr.enumber =~ /_/)}.first
          if preferred_enumber_enrollment.nil?
            self.exclusions << {:protocol => protocol, :ppt_id => ppt_id, :message => "count not find a non-underscore enrollment for this ppt"}
            next
          end

          print "."

          # t2_candidates = visit.image_datasets.select{|image| (image.series_description =~ /ORIG/).nil? and (image.series_description =~ /FLAIR/i) and (image.series_description =~ /T2/)}

          t2_candidates = visits.map{|visit| visit.image_datasets.select{|image| (image.series_description =~ /ORIG/).nil? and ((image.series_description =~ /SAG Cube T2 FLAIR/i)  or (image.series_description =~ /Sag T2 FLAIR Cube/i)  or (image.series_description =~ /Sag CUBE T2FLAIR/i) or (image.series_description =~ /Sag CUBE flair/i) or (image.series_description =~ /CUBE T2FLAIR/i))}}.flatten
          t2_candidates.sort!{|a,b| path_sort(a,b)}
          t2_file = nil
          marked_as_default = []
          if t2_candidates.count == 1
            t2_file = t2_candidates.first
          elsif t2_candidates.count == 0
            self.exclusions << {:protocol => protocol, :ppt_id => ppt_id, :message => "no T2 FLAIR image for this visit"}
            next
          else

            #if we've got 2, we need to see if one has been marked as the default for this visit.

            marked_as_default = t2_candidates.select{|item| item.use_as_default_scan_flag == 'Y'}
            if marked_as_default.count == 1
              t2_file = marked_as_default.first
            else

              # 2020-12-08 wbbevis -- We've got a tie between the candidates on our list of T2 FLAIRs. Since we added
              # the path_sort, that should put any PURE corrected cases to the front of the list, which is what we prefer.

              t2_file = t2_candidates.first

            end
          end

          # Here, we actually need an nii file from preprocessed/visits. The path from the image_dataset is in raw.
          # So, let's see if we can find the .nii.

          t2_nii_path = ''
          if !t2_file.nil?

            subdir_name = t2_file.path.split("/")[6]

            preprocessed_path = "#{params[:base_path]}/preprocessed/visits/#{scan_procedure.codename}/#{preferred_enumber_enrollment.enumber}/#{subdir_name}/unknown"

            # for cases with multiple FLAIR images, one is supposed to be flagged as default, but the object with that
            # flag points to the /raw/ directories, not to preprocessed. In order to find the matching .nii in 
            # preprocessed, we'll need to check to see if there's been one marked as default, and if so add a little
            # more to the regex so that we know which one to pick.

            #default regex
            # 2020-11-17 wbbevis -- Thanks to the dempsy.plaque.visit1 study, this has to account for "+C Sag CUBE T2 FLAIR".
            # These are actual scans, not typos, but they break the regex. 

            # this is ugly, but it works.
            image_number = t2_file.path.split("/").last.split(".").first
            image_number = image_number.gsub(/0/,"")
            series_description_re = Regexp.new("#{t2_file.series_description.gsub(/ /,'[-_ ]').gsub(/\+/,'').gsub(/:/,'[-_ ]')}\\w*#{image_number}*.nii","i")

            if !File.exist?(preprocessed_path) or !File.directory?(preprocessed_path)
              self.exclusions << {:protocol => protocol, :ppt_id => ppt_id, :visits => visits.map(&:id), :message => "no preprocessed path, or doesn't exist", :path => preprocessed_path}
              next
            end

            t2_nii_candidates = Dir.entries(preprocessed_path).select{|img| (img =~ series_description_re) and !(img =~ /ORIG/) and (img =~ /^[^.]/)}

            if t2_nii_candidates.count == 1
              t2_nii_path = "#{preprocessed_path}/#{t2_nii_candidates.first}"
            elsif t2_nii_candidates.count == 0

              self.exclusions << {:protocol => protocol, :ppt_id => ppt_id, :visits => visits.map(&:id),:message => "no T2 FLAIR nii for this visit in preprocessed"}
              next
              
            else

              self.exclusions << {:protocol => protocol, :ppt_id => ppt_id, :visits => visits.map(&:id),:message => "too many T2 FLAIR nii for this visit in preprocessed"}
              next
            end

          end


          acpc_path = nil
          preprocessed_glob = "#{params[:base_path]}/preprocessed/visits/#{scan_procedure.codename}/#{preferred_enumber_enrollment.enumber}/*/unknown/o*.nii"
          acpc_candidates = Dir.glob(preprocessed_glob)
          if acpc_candidates.count > 0
            acpc_path = acpc_candidates.first
          elsif acpc_candidates.count == 0

            self.exclusions << {:protocol => protocol, :ppt_id => ppt_id, :visits => visits.map(&:id),:message => "no o*.nii files for this visit"}
            next
          else
            self.exclusions << {:protocol => protocol, :ppt_id => ppt_id, :visits => visits.map(&:id),:message => "o*.nii file weirdness"}
            next
          end

          #finally, if this case has already been run, don't rerun it.
          processing_path = "#{params[:processing_output_path]}/#{scan_procedure.codename}/#{preferred_enumber_enrollment.enumber}/"
          if File.exists?(processing_path) and File.directory?(processing_path) and Dir.entries(processing_path).select{|item| item =~ /^[^.]/}.count > 0
            self.exclusions << {:protocol => protocol, :ppt_id => ppt_id, :message => "already processed"}
            next
          end

          if acpc_path.nil?
            self.exclusions << {:protocol => protocol, :ppt_id => ppt_id, :visits => visits.map(&:id),:message => "failed to find an acpc file for this case. does one exist?"}
            next
          end

          # dereference the paths, in case I've actually found symlinks
          if File.symlink?(acpc_path)
            acpc_path = File.realpath(acpc_path)
            if !File.exists?(acpc_path)
              self.exclusions << {:protocol => protocol, :ppt_id => ppt_id, :visits => visits.map(&:id),:message => "symlink to acpc file is broken"}
              next
            end
          end

          if File.symlink?(t2_nii_path)
            t2_nii_path = File.realpath(t2_nii_path)
            if !File.exists?(t2_nii_path)
              self.exclusions << {:protocol => protocol, :ppt_id => ppt_id, :visits => visits.map(&:id),:message => "symlink to t2_nii file is broken"}
              next
            end
          end

          @driver << {:protocol => protocol, :ppt_id => ppt_id, :t2_ids => t2_file, :t2_nii_path => t2_nii_path, :acpc_path => acpc_path, :scan_procedure => scan_procedure.codename, :enrollment => preferred_enumber_enrollment}

        end
      end
  end

end