class Jobs::Lst::LstLpaAdniflairDriver < Jobs::Lst::LstLpaDriver

  attr_accessor :ok_paths_and_not_processed_before
  attr_accessor :total_scans_considered
  attr_accessor :selected
  attr_accessor :driver

  def self.default_params
    params = { schedule_name: 'LST/LPA Pipeline Driver - ADNIFLAIR',
                base_path: "/mounts/data", 
                computer: "kanga",
                dry_run: false,
                run_by_user: 'panda_user',
                code_ver: 'b42e83aa',
                exclude_sp_mri_array: [-1,100,80,76,78],
                date_cutoff: '2018-10-11',
                csv_headers: ['scan_procedure','enrollment','ACPC_T1_path','T2_FLAIR', 'processing_flag'],
                driver_path: "/mounts/data/analyses/wbbevis/lst_lpa/",
                driver_file_name: "#{Date.today.strftime("%Y-%m-%d")}_lst_lpa_driver.csv",
                processing_output_path: "/mounts/data/development/lstlpa/output",
                processing_input_path: "/mounts/data/development/lstlpa/input",
                processing_executable_path: "/mounts/data/development/lstlpa/src/run_lpa.sh",
                special_flag: 'ADNIFLAIR'
              }
    params.default = ''
    params
  end

  def self.production_params
    params = { schedule_name: 'LST/LPA Pipeline Driver - ADNIFLAIR',
                base_path: "/mounts/data", 
                computer: "moana",
                dry_run: false,
                run_by_user: 'panda_user',
                code_ver: 'b42e83aa',
                exclude_sp_mri_array: [-1,100,80,76,78],
                date_cutoff: '2015-06-01',
                csv_headers: ['scan_procedure','enrollment','ACPC_T1_path','T2_FLAIR', 'processing_flag'],
                driver_path: "/mounts/data/analyses/wbbevis/lst_lpa/",
                driver_file_name: "#{Date.today.strftime("%Y-%m-%d")}_lst_lpa_driver.csv",
                processing_output_path: "/mounts/data/pipelines/lstlpa/output",
                processing_input_path: "/mounts/data/pipelines/lstlpa/input",
                processing_executable_path: "/mounts/data/pipelines/lstlpa/src/run_lpa.sh",
                special_flag: 'ADNIFLAIR'
              }
    params.default = ''
    params
  end

  def filter(params)

    @selected.each do |visit|

          @total_scans_considered += 1

          vgroup = visit.appointment.vgroup

          #first let's get the primary scan_procedure, and the enrollment

          scan_procedure = visit.related_scan_procedure
          if scan_procedure.nil?
            self.exclusions << {:class => visit.class, :id => visit.id, :message => "scan procedures broken for this visit"}
            next
          end

          enrollment = visit.related_enrollment
          if enrollment.nil?
            self.exclusions << {:class => visit.class, :id => visit.id, :message => "vgroup has no enrollments"}
            next
          end

          print "."

          # 2021-06-07 wbbevis -- this is the only difference between the normal job and this ADNIFLAIR job: which T2 we're picking.

          t2_candidates = visit.image_datasets.select{|image| (image.series_description =~ /ORIG/).nil? and ((image.series_description =~ /Sagittal 3D FLAIR/i)  or (image.series_description =~ /Sag T2 FLAIR Cube/i))}
          t2_candidates.sort!{|a,b| path_sort(a,b)}
          t2_file = nil
          marked_as_default = []
          if t2_candidates.count == 1
            t2_file = t2_candidates.first
          elsif t2_candidates.count == 0
            self.exclusions << {:class => visit.class, :id => visit.id, :message => "no T2 FLAIR image for this visit"}
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

            preprocessed_path = "#{params[:base_path]}/preprocessed/visits/#{scan_procedure.codename}/#{enrollment.enumber}/unknown"

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
            series_description_re = Regexp.new("#{t2_file.series_description.gsub(/ /,'[-_ ]').gsub(/\+/,'').gsub(/:/,'[-_ ]')}\\w*#{image_number}+.nii","i")

            if !File.exist?(preprocessed_path) or !File.directory?(preprocessed_path)
              self.exclusions << {:class => visit.class, :id => visit.id, :message => "no preprocessed path, or doesn't exist"}
              next
            end

            t2_nii_candidates = Dir.entries(preprocessed_path).select{|img| (img =~ series_description_re) and !(img =~ /ORIG/) and (img =~ /^[^.]/)}

            if t2_nii_candidates.count == 1
              t2_nii_path = "#{preprocessed_path}/#{t2_nii_candidates.first}"
            elsif t2_nii_candidates.count == 0

              # before we give up, we should see if there are 2ndary scans for this person's visit, and look to see if there are viable scans in there
              if visit.secondary_dir_exists?

                secondaries = visit.secondary_dirs
                secondaries.each do |secondary|
                  t2_nii_candidates = Dir.entries(secondary).select{|img| (img =~ series_description_re) and !(img =~ /ORIG/) and (img =~ /^[^.]/)}
                  if t2_nii_candidates.count == 1
                    t2_nii_path = "#{preprocessed_path}/#{t2_nii_candidates.first}"
                  elsif t2_nii_candidates.count == 0
                    self.exclusions << {:class => visit.class, :id => visit.id, :message => "no T2 FLAIR nii for this visit in preprocessed"}
                    next
                  else
                    self.exclusions << {:class => visit.class, :id => visit.id, :message => "too many T2 FLAIR nii for this visit in preprocessed"}
                    next
                  end
                end

              else

                self.exclusions << {:class => visit.class, :id => visit.id, :message => "no T2 FLAIR nii for this visit in preprocessed"}
                next
              end
            else

              self.exclusions << {:class => visit.class, :id => visit.id, :message => "too many T2 FLAIR nii for this visit in preprocessed"}
              next
            end

          end


          acpc_path = nil
          if visit.preprocessed_dir_exists?
            acpc_candidates = Dir.entries(visit.preprocessed_dir).select { |f| f.start_with?("o") and f.end_with?(".nii") }
            if acpc_candidates.count == 1
              acpc_path = "#{visit.preprocessed_dir}/#{acpc_candidates.first}"
            elsif acpc_candidates.count == 0

              # before we give up, we should see if there are 2ndary scans for this person's visit, and look to see if there are viable scans in there
              if visit.secondary_dir_exists?

                secondaries = visit.secondary_dirs
                secondaries.each do |secondary|
                  acpc_candidates = Dir.entries(secondary).select { |f| f.start_with?("o") and f.end_with?(".nii") }
                  if acpc_candidates.count == 1
                    acpc_path = "#{preprocessed_path}/#{acpc_candidates.first}"

                  elsif acpc_candidates.count == 0
                    self.exclusions << {:class => visit.class, :id => visit.id, :message => "no o*.nii files for this visit"}
                    next
                  else
                    self.exclusions << {:class => visit.class, :id => visit.id, :message => "too many o*.nii files for this visit"}
                    next
                  end
                end

              else
                self.exclusions << {:class => visit.class, :id => visit.id, :message => "no o*.nii files for this visit"}
                next
              end
            else
              self.exclusions << {:class => visit.class, :id => visit.id, :message => "too many o*.nii files for this visit"}
              next
            end
          else
            self.exclusions << {:class => visit.class, :id => visit.id, :message => "no proprocessed directory for this visit"}
            next
          end

          #finally, if this case has already been run, don't rerun it.
          processing_path = "#{params[:processing_output_path]}/#{scan_procedure.codename}/#{enrollment.enumber}/"
          if File.exists?(processing_path) and File.directory?(processing_path) and Dir.entries(processing_path).select{|item| item =~ /^[^.]/}.count > 0
            self.exclusions << {:class => visit.class, :id => visit.id, :message => "already processed"}
            next
          end

          if acpc_path.nil?
            self.exclusions << {:class => visit.class, :id => visit.id, :message => "failed to find an acpc file for this case. does one exist?"}
            next
          end

          # dereference the paths, in case I've actually found symlinks
          if File.symlink?(acpc_path)
            acpc_path = File.realpath(acpc_path)
            if !File.exists?(acpc_path)
              self.exclusions << {:class => visit.class, :id => visit.id, :message => "symlink to acpc file is broken"}
              next
            end
          end

          if File.symlink?(t2_nii_path)
            t2_nii_path = File.realpath(t2_nii_path)
            if !File.exists?(t2_nii_path)
              self.exclusions << {:class => visit.class, :id => visit.id, :message => "symlink to t2_nii file is broken"}
              next
            end
          end

          @driver << {:visit => visit, :t2_ids => t2_file, :t2_nii_path => t2_nii_path, :acpc_path => acpc_path, :scan_procedure => scan_procedure.codename, :enrollment => enrollment}

      end
  end

end