# encoding: utf-8
class ImageDatasetsController < ApplicationController # AuthorizedController #  ApplicationController
#   load_and_authorize_resource
  require 'csv'
  before_action :set_current_tab  
  before_action :set_image_dataset, only: [:show, :edit, :update, :destroy]   
	respond_to :html
  
  def set_current_tab
    @current_tab = "image_datasets"
  end
  
  def check_image_quality
   scan_procedure_array = (current_user.view_low_scan_procedure_array).split(' ').map(&:to_i)
    @image_dataset = ImageDataset.where("image_datasets.visit_id in (select visit_id from scan_procedures_visits where scan_procedure_id in (?))", scan_procedure_array).find(params[:id])
    @qc = ImageDatasetQualityCheck.new
    @qc.user = current_user
    @qc.image_dataset = @image_dataset
    
    respond_to do |format|
      format.html # check_image_quality.html.erb
    end
  end
  
  # GET /image_datasets
  # GET /image_datasets.xml
  def index
    scan_procedure_array = (current_user.view_low_scan_procedure_array).split(' ').map(&:to_i)

          hide_date_flag_array = []
      hide_date_flag_array =  (current_user.hide_date_flag_array).split(' ').map(&:to_i)
      @hide_page_flag = 'N'
      if hide_date_flag_array.count > 0
        @hide_page_flag = 'Y'
      end
    # caused error -- using old search meta_search -- gem not added
#    @sp_array = []
#    if params[:visit_id]
#      @visit = Visit.where("visits.id in (select visit_id from scan_procedures_visits where scan_procedure_id in (?))", scan_procedure_array).find(params[:visit_id])
#      @search = @visit.image_datasets.search(params[:search])
#      @image_datasets = @search.relation.page(params[:page]).per(50).all
#      @total_count = @image_datasets.count
#      @page_title = "All Image Datasets for Visit #{@visit.rmr}"
#    else
#        #   @image_datasets = ImageDataset.find_all_by_visit_id(params[:visit_id])# .paginate(:page => params[:page], :per_page => PER_PAGE)
#        #   @visit = Visit.find(params[:visit_id])
#        #   @total_count = @image_datasets.count
#        #   @page_title = "All Image Datasets for Visit #{@visit.rmr}"
#        # else
#        if !params[:visit].blank? and !params[:visit][:scan_procedure_id].blank?
#          scan_procedure_id_list = params[:visit][:scan_procedure_id].join(',')
#          @sp_array =   scan_procedure_id_list.split(",")
#          # params[:lh_search][:scan_procedure_id].join(',')
#                if !params[:search].blank? && !params[:search][:meta_sort].blank? ## want to limit  last 2 months when nothing searched for
#                  @page_title = "All Image Datasets "
#           @search = ImageDataset.where("image_datasets.visit_id in (select scan_procedures_visits.visit_id from scan_procedures_visits where scan_procedure_id in (?))
#                                     and image_datasets.visit_id in (select scan_procedures_visits.visit_id from scan_procedures_visits where scan_procedure_id in (?))", scan_procedure_array,params[:visit][:scan_procedure_id]).search(params[:search])
#                elsif !params[:search].blank?
#                  @page_title = "All Image Datasets "
#           @search = ImageDataset.where("image_datasets.visit_id in (select scan_procedures_visits.visit_id from scan_procedures_visits where scan_procedure_id in (?))
#                                               and image_datasets.visit_id in (select scan_procedures_visits.visit_id from scan_procedures_visits where scan_procedure_id in (?))", scan_procedure_array,params[:visit][:scan_procedure_id]).search(params[:search])          
#                else
#                 @page_title = "All Image Datasets "
#          @search = ImageDataset.where("image_datasets.visit_id in (select scan_procedures_visits.visit_id from scan_procedures_visits where scan_procedure_id in (?))
#                                       and image_datasets.visit_id in (select scan_procedures_visits.visit_id from scan_procedures_visits where scan_procedure_id in (?))", scan_procedure_array,params[:visit][:scan_procedure_id]).search(params[:search])
#                 end        
#        else      
#          if !params[:search].blank? && !params[:search][:meta_sort].blank? ## want to limit  last 2 months when nothing searched for
#            @page_title = "All Image Datasets "
#     @search = ImageDataset.where("image_datasets.visit_id in (select scan_procedures_visits.visit_id from scan_procedures_visits where scan_procedure_id in (?))", scan_procedure_array).search(params[:search])
#          elsif !params[:search].blank?
#            @page_title = "All Image Datasets "
#     @search = ImageDataset.where("image_datasets.visit_id in (select scan_procedures_visits.visit_id from scan_procedures_visits where scan_procedure_id in (?))", scan_procedure_array).search(params[:search])          
#          else
#           @page_title = "All Image Datasets - last 2 months"
#    @search = ImageDataset.where("image_datasets.visit_id in (select visits.id from visits where visits.date > DATE_SUB(NOW(), INTERVAL 2 MONTH) )
#                                 and image_datasets.visit_id in (select scan_procedures_visits.visit_id from scan_procedures_visits where scan_procedure_id in (?))", scan_procedure_array).search(params[:search])
#           end 
#         end   
#        #  @search = ImageDataset.search(params[:search])
#
#          # Set pagination and reporting options depending on the requested format
#          # (ie Don't paginate datasets on CSV download.)
#          if params[:format]
#            
#            @image_datasets = @search.relation
#      
#            # Eventually, we'll be able to set exactly what we want included in the 
#            # report from the web interface. For now, we'll do it programatically 
#            # here in the controller.
#            light_include_options = {:image_dataset_quality_checks, :image_comments   }
#            heavy_include_options = {
#              :image_dataset_quality_checks => {:except => [:id]},
#              :image_comments => {:except => [:id]},
#              :visit => {:methods => :age_at_visit, :only => [:scanner_source, :date], :include => {
#                :enrollments => {:only => [:enumber], :include => { 
#                  :participant => { :methods => :genetic_status, :only => [:gender, :wrapnum, :ed_years] }
#                }  }
#              }} 
#            }
#          else
#            @image_datasets = @search.relation.page(params[:page])
#          end
#
#          # @total_count = all_images.size # I'm not sure where this method is coming from, but it's breaking in ActiveResource
#          @total_count = ImageDataset.count
#          
#        end

        respond_to do |format|
          format.html # index.html.erb
          format.xml  { render :text => @image_datasets.to_xml(:except => [:dicom_taghash])}
          format.csv  { render :csv => ImageDataset.csv_download(@image_datasets, heavy_include_options) }
        end
      end
      
      

      def ids_search
           if(!params["ids_search"].blank?) 
              @ids_search_params  = ids_search_params() 
           end
          hide_date_flag_array = []
      hide_date_flag_array =  (current_user.hide_date_flag_array).split(' ').map(&:to_i)
      @hide_page_flag = 'N'
      if hide_date_flag_array.count > 0
        @hide_page_flag = 'Y'
      end
          # make @conditions from search form input, access control in application controller run_search
          @conditions = []
          @current_tab = "image_datasets"
          # ALSO IN CG_SEARCH !!!!!!  need to update if added new categories
          #           @series_desc_categories = {"ASL" => "ASL", 
          # "DSC_Perfusion" => "DSC_Perfusion", 
          # "DTI" => "DTI", 
          # "Fieldmap" => "Fieldmap", 
          # "fMRI_Task" => "fMRI_Task", 
          # "HYDI" => "HYDI", 
          # "mcDESPOT" => "mcDESPOT", 
          # "MRA" => "MRA", 
          # "MT" => "MT", 
          # "Other" => "Other", 
          # "PCVIPR" => "PCVIPR", 
          # "PD/T2" => "PD/T2", 
          # "resting_fMRI" => "resting_fMRI", 
          # "SWI" => "SWI", 
          # "T1_Volumetric" => "T1_Volumetric", 
          # "T2" => "T2", 
          # "T2_Flair" => "T2_Flair", 
          # "T2*" => "T2*"}
          params["search_criteria"] =""

          if params[:ids_search].nil?
               params[:ids_search] =Hash.new  
               condition ="  visits.appointment_id in (select appointments.id from appointments where appointments.appointment_date > DATE_SUB(NOW(), INTERVAL 2 MONTH)  )"
                @conditions.push(condition)
                params["search_criteria"] = params["search_criteria"] +",  visit date after "+(2.months.ago).strftime("%m/%d/%Y")
          end

          if !params[:ids_search][:scan_procedure_id].blank?
             condition =" visits.appointment_id in (select appointments.id from appointments,scan_procedures_vgroups where 
                                                    appointments.vgroup_id = scan_procedures_vgroups.vgroup_id 
                                                    and scan_procedure_id in ("+params[:ids_search][:scan_procedure_id].join(',').gsub(/[;:'"()=<>]/, '')+"))"
             @conditions.push(condition)
             @scan_procedures = ScanProcedure.where("id in (?)",params[:ids_search][:scan_procedure_id])
             params["search_criteria"] = params["search_criteria"] +", "+@scan_procedures.sort_by(&:codename).collect {|sp| sp.codename}.join(", ").html_safe
          end

          if !params[:ids_search][:path].blank?
              var = "%"+params[:ids_search][:path].downcase+"%"
              condition =" image_datasets.path  like '"+var.gsub(/[;:'"()=<>]/, '')+"' "
              @conditions.push(condition)
              params["search_criteria"] = params["search_criteria"] +", Path contains "+params[:ids_search][:path]
          end
  
          if !params[:ids_search][:series_description].blank?
              var = "%"+params[:ids_search][:series_description].downcase+"%"
              condition =" image_datasets.series_description  like '"+var.gsub(/[;:'"()=<>]/, '')+"' "
              @conditions.push(condition)
              params["search_criteria"] = params["search_criteria"] +", Series desc contains "+params[:ids_search][:series_description]
          end
          
          if !params[:ids_search][:series_description_type_id].blank?
              var = params[:ids_search][:series_description_type_id]
              condition =" image_datasets.series_description  in ( select series_description from series_description_maps where series_description_type_id = '"+var.gsub(/[;:'"()=<>]/, '')+"'  )"
              @conditions.push(condition)
              params["search_criteria"] = params["search_criteria"] +", Series category is "+SeriesDescriptionType.find(params[:ids_search][:series_description_type_id]).series_description_type
          end
          

          if !params[:ids_search][:enumber].blank?
            if params[:ids_search][:enumber].include?(',') # string of enumbers
             v_enumber =  params[:ids_search][:enumber].gsub(/ /,'').gsub(/'/,'').downcase
             v_enumber = v_enumber.gsub(/,/,"','")
               condition =" visits.appointment_id in (select appointments.id from enrollment_vgroup_memberships,enrollments, appointments
               where enrollment_vgroup_memberships.vgroup_id= appointments.vgroup_id 
               and enrollment_vgroup_memberships.enrollment_id = enrollments.id and lower(enrollments.enumber) in ('"+v_enumber.gsub(/[;:"()=<>]/, '')+"'))"

            else
              condition =" visits.appointment_id in (select appointments.id from enrollment_vgroup_memberships,enrollments, appointments
              where enrollment_vgroup_memberships.vgroup_id= appointments.vgroup_id 
              and enrollment_vgroup_memberships.enrollment_id = enrollments.id and lower(enrollments.enumber) in (lower('"+params[:ids_search][:enumber].gsub(/[;:'"()=<>]/, '')+"')))"
            end
            @conditions.push(condition)
            params["search_criteria"] = params["search_criteria"] +",  enumber "+params[:ids_search][:enumber]
          end      

          if !params[:ids_search][:rmr].blank? 
              condition =" visits.appointment_id in (select appointments.id from appointments,vgroups
                        where appointments.vgroup_id = vgroups.id and  lower(vgroups.rmr) in (lower('"+params[:ids_search][:rmr].gsub(/[;:'"()=<>]/, '')+"')   ))"
              @conditions.push(condition)           
              params["search_criteria"] = params["search_criteria"] +",  RMR "+params[:ids_search][:rmr]
          end   

          #  build expected date format --- between, >, < 
          v_date_latest =""
          #want all three date parts
          if !params[:ids_search]["#{'latest_timestamp'}(1i)"].blank? && !params[:ids_search]["#{'latest_timestamp'}(2i)"].blank? && !params[:ids_search]["#{'latest_timestamp'}(3i)"].blank?
               v_date_latest = params[:ids_search]["#{'latest_timestamp'}(1i)"] +"-"+params[:ids_search]["#{'latest_timestamp'}(2i)"].rjust(2,"0")+"-"+params[:ids_search]["#{'latest_timestamp'}(3i)"].rjust(2,"0")
          end
          v_date_earliest =""
          #want all three date parts
          if !params[:ids_search]["#{'earliest_timestamp'}(1i)"].blank? && !params[:ids_search]["#{'earliest_timestamp'}(2i)"].blank? && !params[:ids_search]["#{'earliest_timestamp'}(3i)"].blank?
                v_date_earliest = params[:ids_search]["#{'earliest_timestamp'}(1i)"] +"-"+params[:ids_search]["#{'earliest_timestamp'}(2i)"].rjust(2,"0")+"-"+params[:ids_search]["#{'earliest_timestamp'}(3i)"].rjust(2,"0")
           end
          v_date_latest = v_date_latest.gsub(/[;:'"()=<>]/, '')
          v_date_earliest = v_date_earliest.gsub(/[;:'"()=<>]/, '')
          if v_date_latest.length>0 && v_date_earliest.length >0
            condition ="  visits.appointment_id in (select appointments.id from appointments where appointments.appointment_date between '"+v_date_earliest+"' and '"+v_date_latest+"' )"
            @conditions.push(condition)
            params["search_criteria"] = params["search_criteria"] +",  visit date between "+v_date_earliest+" and "+v_date_latest
          elsif v_date_latest.length>0
            condition ="  visits.appointment_id in (select appointments.id from appointments where appointments.appointment_date < '"+v_date_latest+"'  )"
             @conditions.push(condition)
             params["search_criteria"] = params["search_criteria"] +",  visit date before "+v_date_latest 
          elsif  v_date_earliest.length >0
            condition ="  visits.appointment_id in (select appointments.id from appointments where appointments.appointment_date > '"+v_date_earliest+"' )"
             @conditions.push(condition)
             params["search_criteria"] = params["search_criteria"] +",  visit date after "+v_date_earliest
           end

           if !params[:ids_search][:gender].blank?
              condition ="  visits.appointment_id in (select appointments.id from participants,  enrollment_vgroup_memberships, enrollments,appointments
               where enrollment_vgroup_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id 
               and enrollment_vgroup_memberships.vgroup_id = appointments.vgroup_id
                      and participants.gender is not NULL and participants.gender in ("+params[:ids_search][:gender].gsub(/[;:'"()=<>]/, '')+") )"
               @conditions.push(condition)
               if params[:ids_search][:gender] == 1
                  params["search_criteria"] = params["search_criteria"] +",  sex is Male"
               elsif params[:ids_search][:gender] == 2
                  params["search_criteria"] = params["search_criteria"] +",  sex is Female"
               end
           end   

           if !params[:ids_search][:min_age].blank? && params[:ids_search][:max_age].blank?
               condition ="   visits.appointment_id in (select appointments.id from participants,  enrollment_vgroup_memberships, enrollments, scan_procedures_vgroups,appointments
                                  where enrollment_vgroup_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id
                               and  scan_procedures_vgroups.vgroup_id = enrollment_vgroup_memberships.vgroup_id 
                               and appointments.vgroup_id = enrollment_vgroup_memberships.vgroup_id
                               and round((DATEDIFF(appointments.appointment_date,participants.dob)/365.25),2) >= "+params[:ids_search][:min_age].gsub(/[;:'"()=<>]/, '')+"   )"
                @conditions.push(condition)
               params["search_criteria"] = params["search_criteria"] +",  age at visit >= "+params[:ids_search][:min_age]
           elsif params[:ids_search][:min_age].blank? && !params[:ids_search][:max_age].blank?
                condition ="   visits.appointment_id in (select appointments.id from participants,  enrollment_vgroup_memberships, enrollments, scan_procedures_vgroups,appointments
                                   where enrollment_vgroup_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id
                                and  scan_procedures_vgroups.vgroup_id = enrollment_vgroup_memberships.vgroup_id 
                                and appointments.vgroup_id = enrollment_vgroup_memberships.vgroup_id
                            and round((DATEDIFF(appointments.appointment_date,participants.dob)/365.25),2) <= "+params[:ids_search][:max_age].gsub(/[;:'"()=<>]/, '')+"   )"
               @conditions.push(condition)
               params["search_criteria"] = params["search_criteria"] +",  age at visit <= "+params[:ids_search][:max_age]
           elsif !params[:ids_search][:min_age].blank? && !params[:ids_search][:max_age].blank?
              condition ="    visits.appointment_id in (select appointments.id from participants,  enrollment_vgroup_memberships, enrollments, scan_procedures_vgroups,appointments
                                 where enrollment_vgroup_memberships.enrollment_id = enrollments.id and enrollments.participant_id = participants.id
                              and  scan_procedures_vgroups.vgroup_id = enrollment_vgroup_memberships.vgroup_id 
                              and appointments.vgroup_id = enrollment_vgroup_memberships.vgroup_id
                          and round((DATEDIFF(appointments.appointment_date,participants.dob)/365.25),2) between "+params[:ids_search][:min_age].gsub(/[;:'"()=<>]/, '')+" and "+params[:ids_search][:max_age].gsub(/[;:'"()=<>]/, '')+"   )"
             @conditions.push(condition)
             params["search_criteria"] = params["search_criteria"] +",  age at visit between "+params[:ids_search][:min_age]+" and "+params[:ids_search][:max_age]
           end
           # trim leading ","
           params["search_criteria"] = params["search_criteria"].sub(", ","")

           # adjust columns and fields for html vs xls
           #request_format = request.formats.to_s 
           v_request_format_array = request.formats
            request_format = v_request_format_array[0]
           @html_request ="Y"
           case  request_format
             when "[text/html]","text/html" then # ? application/html
               @column_headers = ['Date','Protocol','Enumber','RMR','Directory', 'Series Description','Imaging Details','Quality Check', 'Analysis Exclusions',' ' ] # need to look up values
                   # Protocol,Enumber,RMR,Appt_Date get prepended to the fields, appointment_note appended
               @column_number =   @column_headers.size
               @fields =["SUBSTRING_INDEX(image_datasets.path,'/',-1)","series_description","'peek'","'Quality check'","'Analysis exclusion'","image_datasets.id"] # vgroups.id vgroup_id always first, include table name
# need to substitue peek- details, quality check, eclusion --- need links
                @left_join = [ ] # left join needs to be in sql right after the parent table!!!!!!!
             else    
               @html_request ="N"          
                @column_headers = ['Date','Protocol','Enumber','RMR','series_description','Use as default scan','Do Not Share','dicom_series_uid','dcm_file_count','timestamp','scanned_file','image_uid','id','rep_time','glob','path','bold_reps','mri_coil_name','slices_per_volume','mri_station_name','mri_manufacturer_model_name','visit.age_at_visit','visit.scanner_source','image_comments.comment',
         'image_dataset_quality_checks.incomplete_series','image_dataset_quality_checks.incomplete_series_comment','image_dataset_quality_checks.garbled_series','image_dataset_quality_checks.garbled_series_comment','image_dataset_quality_checks.fov_cutoff','image_dataset_quality_checks.fov_cutoff_comment','image_dataset_quality_checks.field_inhomogeneity','image_dataset_quality_checks.field_inhomogeneity_comment','image_dataset_quality_checks.ghosting_wrapping','image_dataset_quality_checks.ghosting_wrapping_comment',
         'image_dataset_quality_checks.banding','image_dataset_quality_checks.banding_comment','image_dataset_quality_checks.registration_risk','image_dataset_quality_checks.registration_risk_comment','image_dataset_quality_checks.nos_concerns','image_dataset_quality_checks.nos_concerns_comment','image_dataset_quality_checks.motion_warning','image_dataset_quality_checks.motion_warning_comment',
            'image_dataset_quality_checks.omnibus_f','image_dataset_quality_checks.omnibus_f_comment','image_dataset_quality_checks.spm_mask','image_dataset_quality_checks.spm_mask_comment','image_dataset_quality_checks.other_issues',
            'image_dataset_quality_checks.user_id','image_dataset_quality_checks.created_at','image_dataset_quality_checks.updated_at','image_dataset_quality_checks.image_dataset_id','image_comments.updated_at','image_comments.created_at','image_comments.user_id','image_comments.image_dataset_id','Appt Note'] # need to look up values # not seem to be getting Appt note ,'Appt Note'
          
          
          
                      # Protocol,Enumber,RMR,Appt_Date get prepended to the fields, appointment_note appended
                @column_number =   @column_headers.size
                # try left joins on quality check tables, user name
                # weird utc transformations -- utc in db but timestamps from files seem different
                # NEED TO GET GROUP BY by row "group_concat(image_comments.comment separator ', ')"
                @fields =["image_datasets.series_description","image_datasets.use_as_default_scan_flag","image_datasets.do_not_share_scans_flag","image_datasets.dicom_series_uid","image_datasets.dcm_file_count","concat(date_format(image_datasets.timestamp,'%m/%d/%Y'),time_format(timediff( time(image_datasets.timestamp),subtime(utc_time(),time(localtime()))),' %H:%i'))","image_datasets.scanned_file","image_datasets.image_uid","image_datasets.id","image_datasets.rep_time","image_datasets.glob","image_datasets.path","image_datasets.bold_reps","image_datasets.mri_coil_name","image_datasets.slices_per_volume","image_datasets.mri_station_name","image_datasets.mri_manufacturer_model_name","appointments.age_at_appointment","visits.scanner_source","group_concat(image_comments.comment separator ', ')",
        "image_dataset_quality_checks.incomplete_series","image_dataset_quality_checks.incomplete_series_comment","image_dataset_quality_checks.garbled_series","image_dataset_quality_checks.garbled_series_comment","image_dataset_quality_checks.fov_cutoff","image_dataset_quality_checks.fov_cutoff_comment","image_dataset_quality_checks.field_inhomogeneity","image_dataset_quality_checks.field_inhomogeneity_comment","image_dataset_quality_checks.ghosting_wrapping","image_dataset_quality_checks.ghosting_wrapping_comment",
     "image_dataset_quality_checks.banding","image_dataset_quality_checks.banding_comment","image_dataset_quality_checks.registration_risk","image_dataset_quality_checks.registration_risk_comment","image_dataset_quality_checks.nos_concerns","image_dataset_quality_checks.nos_concerns_comment","image_dataset_quality_checks.motion_warning","image_dataset_quality_checks.motion_warning_comment",
                  "image_dataset_quality_checks.omnibus_f","image_dataset_quality_checks.omnibus_f_comment","image_dataset_quality_checks.spm_mask","image_dataset_quality_checks.spm_mask_comment","image_dataset_quality_checks.other_issues",
                 "concat(qc_users.last_name,', ',qc_users.first_name)","concat(date_format(image_dataset_quality_checks.created_at,'%m/%d/%Y'),time_format(timediff( time(image_dataset_quality_checks.created_at),subtime(utc_time(),time(localtime()))),' %H:%i'))","concat(date_format(image_dataset_quality_checks.updated_at,'%m/%d/%Y'),time_format(timediff( time(image_dataset_quality_checks.updated_at),subtime(utc_time(),time(localtime()))),' %H:%i'))","image_dataset_quality_checks.image_dataset_id","concat(date_format(image_comments.updated_at,'%m/%d/%Y'),time_format(timediff( time(image_comments.updated_at),subtime(utc_time(),time(localtime()))),' %H:%i'))","concat(date_format(image_comments.created_at,'%m/%d/%Y'),time_format(timediff( time(image_comments.created_at),subtime(utc_time(),time(localtime()))),' %H:%i'))","concat(users.last_name,', ',users.first_name)","image_comments.image_dataset_id","concat(IFNULL(visits.notes,''),' ',IFNULL(appointments.comment,''))"] 
               
                @group_by = " group by vgroups.id,appointments.appointment_date, vgroups.rmr , image_datasets.series_description,image_datasets.dicom_series_uid,image_datasets.dcm_file_count,image_datasets.image_uid,image_datasets.id,image_dataset_quality_checks.id"

               
                @left_join = ["LEFT JOIN image_dataset_quality_checks on image_datasets.id = image_dataset_quality_checks.image_dataset_id",
                              "LEFT JOIN users qc_users on image_dataset_quality_checks.user_id = qc_users.id",
                            "LEFT JOIN image_comments on image_datasets.id = image_comments.image_dataset_id",
                            "LEFT JOIN users on image_comments.user_id = users.id"] # left join needs to be in sql right after the parent table!!!!!!!   
                            # "LEFT JOIN employees on petscans.enteredpetscanwho = employees.id", 
              # SHOULD  this be in the image_comments left joins???? LEFT JOIN users on image_comments.user_id = users.id             

             end
           @tables =['visits','image_datasets'] # trigger joins --- vgroups and appointments by default
           @order_by =["appointments.appointment_date DESC", "vgroups.rmr"]
           #@results = self.run_search   # in the application controller
           @results = self.run_search_ids    # in the application controller. --- need to do some extra pop/push
          @results_total = @results  # pageination makes result count wrong
          t = Time.now 
          @export_file_title ="Search Criteria: "+params["search_criteria"]+" "+@results_total.size.to_s+" records "+t.strftime("%m/%d/%Y %I:%M%p")
    @csv_array = []
    @results_tmp_csv = []
    @results_tmp_csv.push(@export_file_title)
    @csv_array.push(@results_tmp_csv )
    @csv_array.push( @column_headers)
    @results.each do |result| 
       @results_tmp_csv = []
       for i in 0..@column_number     #-1  # results is an array of arrays%>
          @results_tmp_csv.push(result[i])
       end 
       @csv_array.push(@results_tmp_csv)
    end 
    @csv_str = @csv_array.inject([]) { |csv, row|  csv << CSV.generate_line(row) }.join("") 
          ### LOOK WHERE TITLE IS SHOWING UP
          @collection_title = 'Image Datasets'

          respond_to do |format|
            format.xls # ids_search.xls.erb
            format.csv { send_data @csv_str }
            format.xml  { render :xml => @results_total }       
            format.html {@results = Kaminari.paginate_array(@results).page(params[:page]).per(50)} # ids_search.html.erb
          end
        end
      
      
  # GET /image_datasets/1
  # GET /image_datasets/1.xml
  def show
    scan_procedure_array = (current_user.view_low_scan_procedure_array).split(' ').map(&:to_i)

          hide_date_flag_array = []
      hide_date_flag_array =  (current_user.hide_date_flag_array).split(' ').map(&:to_i)
      @hide_page_flag = 'N'
      if hide_date_flag_array.count > 0
        @hide_page_flag = 'Y'
      end
    @image_dataset = ImageDataset.where("image_datasets.visit_id in (select visit_id from scan_procedures_visits where scan_procedure_id in (?))", scan_procedure_array).find(params[:id])
    @visit = @image_dataset.visit
    @image_datasets = @visit.image_datasets
    @lock_default_scan_flag_parse = "N|"
    if @image_dataset.lock_default_scan_flag == "Y"
       if @image_dataset.use_as_default_scan_flag == "Y"
            @lock_default_scan_flag_parse = "Y|Y"
        elsif @image_dataset.use_as_default_scan_flag == "N"
            @lock_default_scan_flag_parse = "Y|N"
        else
            @lock_default_scan_flag_parse = "Y|"
        end
    end
    
    @image_comment = ImageComment.new
    @image_comments = @image_dataset.image_comments
    @next_image_dataset = @image_datasets[@image_datasets.index(@image_dataset) + 1 ]
    @previous_image_dataset = @image_datasets[@image_datasets.index(@image_dataset) - 1 ]
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @image_dataset }
    end
  end

  # GET /image_datasets/new
  # GET /image_datasets/new.xml
  def new
    @image_dataset = ImageDataset.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @image_dataset }
    end
  end

  # GET /image_datasets/1/edit
  def edit
    scan_procedure_array = (current_user.edit_low_scan_procedure_array).split(' ').map(&:to_i)

          hide_date_flag_array = []
      hide_date_flag_array =  (current_user.hide_date_flag_array).split(' ').map(&:to_i)
      @hide_page_flag = 'N'
      if hide_date_flag_array.count > 0
        @hide_page_flag = 'Y'
      end
    @image_dataset = ImageDataset.where("image_datasets.visit_id in (select visit_id from scan_procedures_visits where scan_procedure_id in (?))", scan_procedure_array).find(params[:id])
  end

  # POST /image_datasets
  # POST /image_datasets.xml
  def create
    @image_dataset = ImageDataset.new(image_dataset_params)#params[:image_dataset])
    @image_dataset.user = current_user
    respond_to do |format|
      if @image_dataset.save
        # problem with some SCREENSAVE sereies description, null rep_time causing error
        if @image_dataset.series_description == 'SCREENSAVE' and @image_dataset.rep_time.blank?
          @image_dataset.rep_time = 0
          @image_dataset.save
          # if save not work
          #sql = "UPDATE image_datasets set rep_time=0 where rep_time is NULL and id="+@image_dataset.id.to_s
          #connection = ActiveRecord::Base.connection();
          #results = connection.execute(sql)
        end
        flash[:notice] = 'ImageDataset was successfully created.'
        format.html { redirect_to(@image_dataset) }
        format.xml  { render :xml => @image_dataset, :status => :created, :location => @image_dataset }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @image_dataset.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /image_datasets/1
  # PUT /image_datasets/1.xml
  def update
    scan_procedure_array = (current_user.edit_low_scan_procedure_array).split(' ').map(&:to_i)
          hide_date_flag_array = []
      hide_date_flag_array =  (current_user.hide_date_flag_array).split(' ').map(&:to_i)
      @hide_page_flag = 'N'
      if hide_date_flag_array.count > 0
        @hide_page_flag = 'Y'
      end
    @image_dataset = ImageDataset.where("image_datasets.visit_id in (select visit_id from scan_procedures_visits where scan_procedure_id in (?))", scan_procedure_array).find(params[:id])
    if !params[:image_dataset][:lock_default_scan_flag_parse].blank?  
           v_lock_default_scan_array = params[:image_dataset][:lock_default_scan_flag_parse].split("|")
            @image_dataset.lock_default_scan_flag = v_lock_default_scan_array[0]
            if v_lock_default_scan_array[1] == ''
                  @image_dataset.use_as_default_scan_flag =nil
            else
                  @image_dataset.use_as_default_scan_flag = v_lock_default_scan_array[1]
            end 
    end

    respond_to do |format|
      if @image_dataset.update(image_dataset_params)#params[:image_dataset], :without_protection => true)
        flash[:notice] = 'ImageDataset was successfully updated.'
        format.html { redirect_to(@image_dataset) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @image_dataset.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /image_datasets/1
  # DELETE /image_datasets/1.xml
  def destroy
    scan_procedure_array = (current_user.edit_low_scan_procedure_array).split(' ').map(&:to_i)
          hide_date_flag_array = []
      hide_date_flag_array =  (current_user.hide_date_flag_array).split(' ').map(&:to_i)
      @hide_page_flag = 'N'
      if hide_date_flag_array.count > 0
        @hide_page_flag = 'Y'
      end
    @image_dataset = ImageDataset.where("image_datasets.visit_id in (select visit_id from scan_procedures_visits where scan_procedure_id in (?))", scan_procedure_array).find(params[:id])
    @image_dataset.destroy

    respond_to do |format|
      format.html { redirect_to(image_datasets_url) }
      format.xml  { head :ok }
    end
  end  
  private
    def set_image_dataset
       @image_dataset = ImageDataset.find(params[:id])
    end
   def image_dataset_params
          params.require(:image_dataset).permit(:lock_default_scan_flag_parse,:scanned_file,:slices_per_volume,:bold_reps,:rep_time,:glob,:visit_id,:timestamp,:path,:series_description,:rmr,:thumbnail_file_name,:thumbnail_content_type,:mri_coil_name,:mri_station_name, :mri_manufacturer_model_name,:lock_default_scan_flag,:use_as_default_scan_flag,:coil_channel_number,:do_not_share_scans_flag,:image_uid,:dicom_taghash,:dicom_series_uid,:thumbnail_updated_at,:thumbnail_file_size,:id,:dcm_file_count,:thumbnail,:thumb)
   end  
   def ids_search_params
          params.require(:ids_search).permit!
   end
end
