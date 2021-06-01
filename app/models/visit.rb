class Visit < ActiveRecord::Base
  RADIOLOGY_OUTCOMES = %w{no Nm A-F A-NF n/a}
  PROGRESS_CHOICES = %w{no yes n/a}
    EXCLUDED_REPORT_ATTRIBUTES = [:user_id ,:initials]
    # Note: As of 8/24/2011, default excludes (:except => :id) are not working.
    # Use the Class Constant ImageDataset::EXCLUDED_REPORT_ATTRIBUTES instead.
    acts_as_reportable

   
  # default_scope :order => 'date DESC', :include => [:scan_procedure, {:enrollment => :participant} ]
  #default_scope :order => 'date DESC'   
  default_scope { order(date: :desc) }
  
  validates_presence_of :date

  # Allow the DICOM UID to be blank for visits without Scans
  validates_uniqueness_of :dicom_study_uid, :case_sensitive => false, :unless => Proc.new {|visit| visit.dicom_study_uid.blank?}
  
  has_and_belongs_to_many :scan_procedures
 
  has_many :image_datasets, :dependent => :destroy  
  #### test added changed Image datasets is invalid error to Image datasets thumbnail Paperclip::Errors::NotIdentifiedByImageMagickError  
  accepts_nested_attributes_for :image_datasets
  has_many :radiology_comments, :dependent => :destroy
  # rails 5 ?accepts_nested_attriubtes_for :image_datasets
 # belongs_to :appointment
 has_many :mriscantasks,:dependent => :destroy
  has_many :log_files
  belongs_to :user
  # has_one :participant, :through => :enrollment  # Defined manually because of has_many :enrollments
  has_one :neuropsych_session
  belongs_to :created_by, :class_name => "User"
  
  validates_inclusion_of :radiology_outcome, :in => RADIOLOGY_OUTCOMES
  # moved to vgroups
  # validates_inclusion_of :transfer_mri, :transfer_pet, :conference, :compile_folder, :in => PROGRESS_CHOICES
   validates_inclusion_of :conference, :in => PROGRESS_CHOICES
  
  has_many :enrollment_visit_memberships
  # has_many :enrollments, :through => :enrollment_visit_memberships, :uniq => true  
  # has_many :enrollments, -> { uniq }, :through => :enrollment_visit_memberships   
   has_many :enrollments, -> { distinct }, :through => :enrollment_visit_memberships 
  accepts_nested_attributes_for :enrollments, :reject_if => :all_blank, :allow_destroy => true
  ##  think preventing duplicate records 
  before_validation :lookup_enrollments
  
  # moved to vgroups
  # before_validation :update_compiled_at_date, :if => Proc.new {|v| v.compile_folder_changed? }
  #scope :complete, where(:compile_folder => "yes")
  #scope :incomplete, where(:compile_folder => "no")
  scope :recently_imported, lambda{ where("created_at => ?",1.week.ago)   }
  scope :assigned_to, lambda { |user_id|
    { :conditions => { :user_id => user_id } }
  }
  scope :in_scan_procedure, lambda { |protocol_id|
    { :conditions => { :scan_procedure_id => protocol_id } }
  }
  
  #scope :without_enrollments, where("id NOT IN (SELECT visit_id FROM enrollment_visit_memberships)")   
  scope :without_enrollments, lambda{where("id NOT IN (SELECT visit_id FROM enrollment_visit_memberships)") }
  
  paginates_per 50
  
  delegate :enumber, :to => :enrollment, :prefix => true

  has_one :sharing, :as => :shareable, :dependent => :destroy

  def shareable?(category=nil)
    !sharing.nil? ? sharing.shareable?(category) : appointment.shareable?(category)
  end

  def heal_sharing

    if self.sharing.nil?
      self.sharing = Sharing.new(:shareable => self)
      self.sharing.save
    end

 end
  
  acts_as_reportable
  def appointment
      @appointment =Appointment.find(self.appointment_id)
      return @appointment
  end
  
  def participant
    @participant ||= nil
    return @participant if @participant

    unless enrollments.blank?
      enrollments.each {|enrollment| @participant = enrollment.participant unless enrollment.participant.blank? }
    end
    return @participant
  end
  def rmr_scan_date
    "#{self.rmr} #{self.scan_number} #{Date.strptime(self.date.to_s).strftime('%m/%d/%Y')}  "
  end
 # the enumber collection adds 3x load time
  def rmr_scan_date_enroll_collection
    "#{self.rmr}  # #{self.scan_number} #{Date.strptime(self.date.to_s).strftime('%m/%d/%Y')} -- #{self.enrollments.collect {|e| e.enumber }.join(", ")}"
  end
  
  def week
    self.date.beginning_of_week
  end
  
  def month
    self.date.beginning_of_month
  end
  
  def self.scanner_sources
    find_by_sql('select DISTINCT(scanner_source) from visits').map { |v| v.scanner_source }.compact
  end
  
  def enrollments_list
    enrollments.collect {|enroll| enroll.enumber }.join(", ")
  end
  
  
  
  # Create or update an ActiveRecord Visit model using attributes from
  # a metamri VisitRawDataDirectory
  # 
  # === Arguments
  # 
  # * <tt>v</tt> -- Metamri::VisitRawDataDirectory. A VisitRawDataDirectory that has already been initialized and v.scan'ed, so it has datasets.
  # * <tt>created_by</tt> -- WADRC-Data-Tools::User. An optional user who will be credited with creating the Visit.
  # 
  def self.create_or_update_from_metamri(v, created_by = nil)
    created_by ||= User.first
puts "WWWWWWWWWWWW in create_or_update_from_metamri"    
    sp = ScanProcedure.find_or_create_by(codename: v.scan_procedure_name)
    v_series_desc_time_stamp_cleanup_array = ["CDT","CBF","ADC","FA","Trace","AvDC"]
    
    # Build an ActiveRecord Visit object using available attributes from metamri.
    # We need to handle Old Studies involving GE I-Files, which don't have any true UID
    visit_attrs = v.attributes_for_active_record.merge(:scan_procedure_ids => [sp.id])
    v_alternative_rmr_dicom_header_field = ""
    sps = [sp]
    # metmri expects the RMRaicXXXXXX in 0010,0020  Patient ID
    # the A$ study is putting the RMRaic###### in 0008,005
    # at the scan procedure level , adding alternative rmr field
    # is getting the rmr correctly, but not making the participant via reggieid
    sps.each do |sss|
       if !sss.rmr_dicom_field.nil? and !(sss.rmr_dicom_field).empty?
          v_alternative_rmr_dicom_header_field = sss.rmr_dicom_field
        end
    end
    if !v_alternative_rmr_dicom_header_field.empty?  #0008,0050|Accession Number
      v_rmr_dicom = v_alternative_rmr_dicom_header_field.split("|")
      #  visit_attrs[:rmr] ="RMRaic006918"
      absfilepath= (v.datasets.first).directory
      if File.exist?("#{File.join(absfilepath, "I0001.dcm")}.bz2")
         file_to_scan = Pathname.new("#{File.join(absfilepath, "I0001.dcm")}.bz2").local_copy(Dir.mktmpdir).to_s
         absfilepath = File.expand_path(file_to_scan)

        @current_hdr_reader = "printraw"
         header = `printraw '#{absfilepath}' 2> /dev/null`
         header = header.encode("UTF-8", :invalid => :replace, :undef => :replace, :replace => "").force_encoding('UTF-8')
         if ( header.chomp != "" and header.length > 400)
              visit_attrs[:rmr] = header[v_rmr_dicom[0]].value
          else
            header = DICOM::DObject.read(absfilepath)
            visit_attrs[:rmr] = header[v_rmr_dicom[0]].value
         end
      end
    end
    if visit_attrs[:dicom_study_uid]        #==> in visit table/ from ids.dicom_hashtag
      # deprteciated nope visit = Visit.find_or_initialize_by_dicom_study_uid(visit_attrs)
        # nope visit = Visit.find_or_initialize_by(dicom_study_uid: visit_attrs)
      visit = Visit.where(dicom_study_uid: visit_attrs[:dicom_study_uid]).first_or_initialize  
    else
      #visit = Visit.find_or_initialize_by_rmr(visit_attrs) 
      visit = Visit.find_or_initialize_by(rmr: visit_attrs[:dicom_study_uid])   # not tested   - think is working 
    end
    # CHECK IN DEV IF THIS IS WORKING - IS THIS WHERE visit.date comes from 
    # what is visit_attrs
    visit.date = visit_attrs[:date]  
    visit.rmr = visit_attrs[:rmr]
    visit.path = visit_attrs[:path]
    visit.scan_number = visit_attrs[:scan_number]
    visit.dicom_study_uid = visit_attrs[:dicom_study_uid]
    #visit.attributes.merge!(visit_attrs) #### VISIT NOT GETTING values from visit_attrs==>no values   
    visit.scan_procedures = [sp]  
    
    # We have to zip up the metamri datasets and the activerecord visit datasets
    # For each dataset in the VisitRawDataDirectory... 
    # rails 5 not have merge! - not hash but objects -- want to limit to unique dicom_series_uid 
    # merge is probably doing other things
    # merging on visit.image_dataset.....
    v_dicom_series_uid_unique_check_array = []   # standin for merge? 
        v_non_unique_datasets = [] 
        v.datasets.each do |dataset|
         v_skip_this_dataset ="N"  
         if  !dataset.dicom_series_uid.nil?  and dataset.dicom_series_uid > ""
             puts "dataset.dicom_series_uid not nill and >'' "
            if v_dicom_series_uid_unique_check_array.include?(dataset.dicom_series_uid)
                v_skip_this_dataset ="Y" 
               puts "dataset.dicom_series_uid not nill and >'' AND in v_dicom_series_uid_unique_check_array"
              v_non_unique_datasets.push(dataset)  
            else
               v_dicom_series_uid_unique_check_array.push(dataset.dicom_series_uid)
            end
         end
        end  
        v_non_unique_datasets.each do |dataset_delete| 
            v.datasets.delete_if {|obj| obj == dataset_delete}
        end

    v.datasets.each do |dataset|
      begin 
        # Skip directories that are links.
        next if File.symlink? dataset.directory
        puts "ggggggggg imagedatasets "
        # Initialize Thumbnail (or nil)
        # Note: Using Metamri#RawImageDatasetThumbnail Directly
       metamri_attr_options = {}
        begin 
  puts "XXXXXXXX before RawImageDatasetThumbnail.new(dataset).thumbnail"
       v_path_tmp = RawImageDatasetThumbnail.new(dataset).thumbnail
        puts "hhhh v_path_tmp ="+v_path_tmp
#       v_image_tmp = File.open(v_path_tmp) 
#      stopped error when removed ids has_attachment styles <Paperclip::Errors::NotIdentifiedByImageMagickError: Paperclip::Errors::NotIdentifiedByImageMagickError>
  #### stopping to test -- if block ids ok, no thumbs    
  metamri_attr_options[:thumb] = File.open(v_path_tmp) #RawImageDatasetThumbnail.new(dataset).thumbnail) 
  puts "ZZZZZZZZZZ after RawImageDatasetThumbnail.new(dataset).thumbnail"   # not sure where it fails after this
        rescue StandardError, ScriptError => e
          puts "WWWWWWWWW in rescue RawImageDatasetThumbnail.new(dataset).thumbnail"
          logger.debug e
          puts "hhhhh"
        end
        # Test to see if this dataset already exists and grab it if so,
        # otherwise build it fresh. This fails if the image dataset exists but
        # is not associated with the visit, since it's essentially scoping
        # inside the visit. Fix this by just querying ImageDataset directly and
        # update. 
        # 
        # This will not reassociate the dataset with the current visit.
        # 
        # data = visit.image_datasets.select {|ds| ds.dicom_series_uid.to_s == dataset.dicom_series_uid.to_s }.first
        if dataset.dicom?  
          data = ImageDataset.where(:dicom_series_uid => dataset.dicom_series_uid).first  
 
        elsif dataset.pfile? or dataset.geifile? or dataset.scan_archive_h5_json?
          #data = ImageDataset.where(:path => dataset.directory, :scanned_file.matches => dataset.scanned_file).first
          data = ImageDataset.where("path in (?) and scanned_file in (?)", dataset.directory,  dataset.scanned_file).first
          #data = data.to_h
        else raise StandardError, "Could not identify type of dataset #{File.join(dataset.directory, datset.scanned_file)}"
        end

        meta_attrs = dataset.attributes_for_active_record(metamri_attr_options) 
        # If the ActiveRecord Visit (visit) has a dataset that already matches the metamri dataset (dataset) on dicom_series_uid, then use it and update its params.  Otherwise, build a new one.
        unless data.blank? # AKA data.kind_of? ImageDataset
           logger.debug "updating dataset #{data.id} with new metamri attributes"
           data.attributes.merge!(meta_attrs)  # DOES THIS WORK  
          
          if data.valid?
            # this just gets the existing ids
            # waisman has  desc:Mon dd yyyy hh-mm-ss CDT e.g. FA:Oct 09 2017 08-46-40 CDT
            # want to detect, and split on :, take first part as series description
            # CDT 
            #CBF
            #eADC
            #ADC
            #FA
            #Trace
            v_series_desc_tmp = nil
             # also LINE 282
            v_series_desc_time_stamp_cleanup_array.each do |v_desc|
             if  (dataset.series_description).include? v_desc 
              if ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'].any? { |word| (dataset.series_description).include?(word) }
                 v_series_desc_tmp = (dataset.series_description).split(":")
                 if !v_series_desc_tmp.blank? and !v_series_desc_tmp[0].blank? 
                     data.series_description = v_series_desc_tmp[0]
                  #puts "zzzttttt  series_description ="+dataset.series_description+"====="+v_series_desc_tmp[0]
                 end
               end
              end
            end

            puts "ggggg data valid"
            visit.image_datasets << data  
            puts " after data into v.ids"
            
          else     
            puts " ffff data not valid"
             data.errors.messages.values.each do |msg|
                msg.each do |m|
                  puts m
                end
              end

            raise StandardError, "Image Dataset #{data.path} not valid: #{e}"
          end
        else
          #puts "PPPPPPPP meta_attrs ="+meta_attrs[:series_description]
            v_series_desc_tmp = nil
            v_series_desc_time_stamp_cleanup_array.each do |v_desc|
            if  (meta_attrs[:series_description]).include? v_desc 
              if ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'].any? { |word| (meta_attrs[:series_description]).include?(word) }
                 v_series_desc_tmp = (meta_attrs[:series_description]).split(":")
                 if !v_series_desc_tmp.blank? and !v_series_desc_tmp[0].blank? 
                     meta_attrs[:series_description] = v_series_desc_tmp[0]
                   #puts "zzzttttt  series_description ="+meta_attrs[:series_description]+"====="+v_series_desc_tmp[0]
                 end
               end
              end
            end
          logger.debug "building fresh visit. image_datasets.build(#{meta_attrs})"
          visit.image_datasets.build(meta_attrs)  
          #visit.save
          #visit.image_datasets.create(meta_attrs) # parent needs to be saved -- not saving visit unless ids work out
          
          logger.debug(visit.image_datasets.last.errors.inspect) unless visit.image_datasets.last.valid?
        end

      rescue Exception => e
        puts "Error building image_dataset. #{e}"
        raise e
      ensure
        #### not sure if needed metamri_attr_options[:thumb].close if metamri_attr_options[:thumb].kind_of? File
      end
    end
 
    visit.created_by = created_by
    # added 20120502 to make mri appointment and the vgroup
    logger.debug "aaaaaaaaa before visit.appointment_id.blank?"  
    if visit.appointment_id.blank?
       appointment = Appointment.create
       appointment.appointment_type ='mri'
       appointment.appointment_date = visit.date
       vgroup = Vgroup.create
       vgroup.vgroup_date = visit.date
       vgroup.rmr = visit.rmr 
       if visit.path > ""
          vgroup.transfer_mri = 'yes' 
       end
       vgroup.save
       appointment.vgroup_id = vgroup.id
       appointment.save
       vital = Vital.new
       vital.appointment_id = appointment.id
       vital.save
       visit.appointment_id = appointment.id
    else
       # not sure why there would be a visit.appointment_id -- getting an error in sql = "Delete from scan_procedures_vgroups where vgroup_id ="+vgroup.id.to_s ???
       appointment = Appointment.find(visit.appointment_id)
       vgroup = Vgroup.find(appointment.vgroup_id)
    end    
    if visit.save
      puts "aaaaaaa saved visit"
    else
      puts "bbbbbbb not saved visit" 
      puts visit.errors.full_messages
    end
    sql = "Delete from scan_procedures_vgroups where vgroup_id ="+vgroup.id.to_s
    connection = ActiveRecord::Base.connection();        
    results = connection.execute(sql)
    sql = "select distinct scan_procedure_id from scan_procedures_visits where visit_id in (select visits.id from visits, appointments where appointments.id = visits.appointment_id and appointments.vgroup_id ="+vgroup.id.to_s+")"
    connection = ActiveRecord::Base.connection();        
    results = connection.execute(sql)
    results.each do |sp|           
      sql = "Insert into scan_procedures_vgroups(vgroup_id,scan_procedure_id) values("+vgroup.id.to_s+","+sp[0].to_s+")"
      connection = ActiveRecord::Base.connection();        
      results = connection.execute(sql)        
    end


           # works in update - makes participant if blank and   sp.make_participant_flag == 'Y'
        if (vgroup.participant_id).blank?

            # check if sp.make_participant_flag == 'Y'
            @scan_procedures = ScanProcedure.where("scan_procedures.id in ( select scan_procedure_id from scan_procedures_vgroups where vgroup_id in (?))",vgroup.id )
            @scan_procedures.each do |sp|
              if sp.make_participant_flag == "Y"  and (vgroup.participant_id).blank?
                 v_new_participant = Participant.new
                 v_new_participant.save
                 vgroup.participant_id = v_new_participant.id
                 vgroup.save
                 @enrollment = Enrollment.where("enrollments.id in ( select enrollment_id from enrollment_vgroup_memberships where vgroup_id in (?) )",vgroup.id )
                 @enrollment.each do |ee|
                   if (ee.participant_id).blank?
                      ee.participant_id = v_new_participant.id
                      ee.save
                   end
                 end
              end
            end
        end

    return visit

  end
  

  def age_at_visit
    # changed 20120808 so preferentially use participant dob instead of age from dicom header
####    return age_from_dicom_info[:age] unless age_from_dicom_info[:age].blank?

####    unless enrollments.blank?
####      enrollments.each do |enrollment|
####        unless enrollment.participant.blank?
####          unless enrollment.participant.dob.blank?
####            participant_dob = enrollment.participant.dob
####          end
####        end
####      end
####    end
    
####    dob = age_from_dicom_info[:dob] ||= participant_dob ||= nil

####    unless dob.blank?
####      date.year - dob.year - ((date.month > dob.month || (date.month == dob.month && date.day >= dob.day)) ? 0 :1 ) unless dob.nil?
####    end
  participant_dob = nil
  age_at_visit = nil
  # get participant dob 1st
      unless enrollments.blank?
        enrollments.each do |enrollment|
          unless enrollment.participant.blank?
            unless enrollment.participant.dob.blank?
              participant_dob = enrollment.participant.dob
            end
          end
        end
      end   
    # participant_dob.to_s  yyyy-mm-dd
    appointment = Appointment.find(self.appointment_id)

    dob = participant_dob ||= age_from_dicom_info[:dob] ||= nil
    if dob.blank?
      age_at_visit = age_from_dicom_info[:age] unless age_from_dicom_info[:age].blank?
    else
      age_at_visit = ((appointment.appointment_date - dob)/365.25).round(2)
    end
    return age_at_visit
  end

 # there are multiple mri_coil_name from different ids in the same scan - trying to 
  def mri_coil_name_from_dicom_info  # 32 vs 8
      @mri_coil_info ||= {}
    return @mri_coil_info unless @mri_coil_info.blank?
    # tags[#] sometimes its just returning # -- a string? 
    image_datasets.each do |dataset|
      if  dataset.dicom_taghash  
        tags = dataset.dicom_taghash      
        if @mri_coil_info[:name].blank? and !tags['0018,1250'].blank? and tags['0018,1250'] != '0018,1250' and tags['0018,1250'][:value] != '' and tags['0018,1250'][:value] !=  'HDNV Array'  and tags['0018,1250'][:value] != 'Perfusion ROIs'  and tags['0018,1250'][:value] != 'BODY'   and tags['0018,1250'][:value] != 'FMT (color)'  and tags['0018,1250'][:value] != 'MTT(CVP) (color)' and tags['0018,1250'][:value] != 'flow:SVDbc (color)' and tags['0018,1250'][:value] !=  'rCBV (color)'  and tags['0018,1250'][:value] != 'rCBV'  and tags['0018,1250'][:value] != 'flow:SVD (bc)' and tags['0018,1250'][:value] != 'FMT' and tags['0018,1250'][:value] != 'MTT(CVP)'
              @mri_coil_info[:name] = tags['0018,1250'][:value].blank? ? nil : tags['0018,1250'][:value].to_s  # age
         end
      end 
    end
     # retry with no restriction
        image_datasets.each do |dataset|
      if  dataset.dicom_taghash  
        tags = dataset.dicom_taghash      
        if @mri_coil_info[:name].blank? and !tags['0018,1250'].blank? and tags['0018,1250'] != '0018,1250' and tags['0018,1250'][:value] != ''
              @mri_coil_info[:name] = tags['0018,1250'][:value].blank? ? nil : tags['0018,1250'][:value].to_s  # age
         end
      end 
    end 
    return @mri_coil_info 
  end 
  def mri_station_name_from_dicom_info  # 32 vs 8
      @mri_station_info ||= {}
    return @mri_station_info unless @mri_station_info.blank?
    # tags[#] sometimes its just returning # -- a string? 
    image_datasets.each do |dataset|
      if  dataset.dicom_taghash  
        tags = dataset.dicom_taghash      
        if @mri_station_info[:name].blank? and !tags['0008,1010'].blank? and tags['0008,1010'] != '0008,1010' and tags['0008,1010'][:value] != '' #and tags['0008,1010'][:value] !=  'HDNV Array'  
              @mri_station_info[:name] = tags['0008,1010'][:value].blank? ? nil : tags['0008,1010'][:value].to_s  # age
         end
      end 
    end
     # retry with no restriction
        image_datasets.each do |dataset|
      if  dataset.dicom_taghash  
        tags = dataset.dicom_taghash      
        if @mri_station_info[:name].blank? and !tags['0008,1010'].blank? and tags['0008,1010'] != '0008,1010' and tags['0008,1010'][:value] != ''
              @mri_station_info[:name] = tags['0008,1010'][:value].blank? ? nil : tags['0008,1010'][:value].to_s  # age
         end
      end 
    end 
    return @mri_station_info 
  end 
  def mri_manufacturer_model_name_from_dicom_info  # 32 vs 8
      @mri_manufacturer_model_info ||= {}
    return @mri_manufacturer_model_info unless @mri_manufacturer_model_info.blank?
    # tags[#] sometimes its just returning # -- a string? 
    image_datasets.each do |dataset|
      if  dataset.dicom_taghash  
        tags = dataset.dicom_taghash      
        if @mri_manufacturer_model_info[:name].blank? and !tags['0008,1090'].blank? and tags['0008,1090'] != '0008,1090' and tags['0008,1090'][:value] != '' # and tags['0008,1090'][:value] !=  'HDNV Array' 
              @mri_manufacturer_model_info[:name] = tags['0008,1090'][:value].blank? ? nil : tags['0008,1090'][:value].to_s  # age
         end
      end 
    end
     # retry with no restriction
        image_datasets.each do |dataset|
      if  dataset.dicom_taghash  
        tags = dataset.dicom_taghash      
        if @mri_manufacturer_model_info[:name].blank? and !tags['0008,1090'].blank? and tags['0008,1090'] != '0008,1090' and tags['0008,1090'][:value] != ''
              @mri_manufacturer_model_info[:name] = tags['0008,1090'][:value].blank? ? nil : tags['0008,1090'][:value].to_s  # age
         end
      end 
    end 
    return @mri_manufacturer_model_info 
  end


  
  def age_from_dicom_info
    @age_info ||= {}
   return @age_info unless @age_info.blank?
    # tags[#] sometimes its just returning # -- a string? 
    image_datasets.each do |dataset|
      if  dataset.dicom_taghash  
        tags = dataset.dicom_taghash      
        if @age_info[:age].blank? and !tags['0010,1010'].blank? and tags['0010,1010'] != '0010,1010' and tags['0010,1010'][:value] != 'XX' and tags['0010,1010'][:value] != '00/00/0000'
              @age_info[:age] = tags['0010,1010'][:value].blank? ? nil : tags['0010,1010'][:value].to_i  # age
         end
         if @age_info[:dob].blank? and !tags['0010,0030'].blank? and tags['0010,0030'] != '0010,0030' and tags['0010,0030'][:value] != 'XX' and tags['0010,1010'][:value] != '00/00/0000' 
             # getting XX   
            if tags['0010,0030'][:value] != "00/00/0000" and tags['0010,0030'][:value] != "XX"
              @age_info[:dob] = tags['0010,0030'][:value].blank? ? nil :  Date.strptime(tags['0010,0030'][:value],'%Y%m%d')
            end 
             # @age_info[:dob] = tags['0010,0030'][:value].blank? ? nil : begin DateTime.parse(tags['0010,0030'][:value]) rescue ArgumentError; nil end   
          end
      end
    end
        # @age_info[:age] ="33"
        # @age_info[:dob] = nil #19540804
    return @age_info
 #   @age_info.each do  |f|
#puts "aaaaaa @age_info.each="+f.to_s
#    end
#     @age_info_array = @age_info.each { |hash| [hash[0], hash[1]] }
#puts "bbbbbb @age_info_array = "+@age_info_array.to_s
#    return @age_info_array
  end
  
  
  def series_desc_cnt(p_start_id, p_end_id)  ## duplicate of visit_controller function 
    @v_start_id=""
    @v_end_id = "" 
    if !p_start_id.blank? and !p_end_id.blank?
         @v_start_id = p_start_id
         @v_end_id = p_end_id
         @image_datasets = ImageDataset.where( " id between "+p_start_id+" and "+p_end_id ).where(" dcm_file_count is null ").where(" glob is not null")
         @image_datasets.each do |ids|
         v_path = (ids.path).gsub('team','team*')
         if !ids.glob.blank?
           v_glob = (ids.glob).gsub('*.dcm','*.dcm*')
           v_count = `cd #{v_path};ls -1 #{v_glob}| wc -l`.to_i   # 
           ids.dcm_file_count = v_count
           ids.save      
         end
       end
     end
      return "ok"
  end
  
  def find_first_dicom_study_uid
    uid = ''
    image_datasets.each do |dataset|
      tags = dataset.dicom_taghash
      unless tags.blank?
        if !tags['0020,000D'].blank? and tags['0020,000D'] != '0020,000D'
            uid = tags['0020,000D'][:value] unless tags['0020,000D'][:value].blank?
        end
      end
    end
    return uid
  end
  
  def initials_from_dicom_or_model
    initials.blank? ? initials_from_dicom_info : initials
  end
  
  def initials_from_dicom_info
    @initials ||= nil
    return @initials unless @initials.blank?
    
    image_datasets.each do |dataset|  
     begin 
      if tags = dataset.dicom_taghash and !tags['0010,0010'].blank? and tags['0010,0010'] != '0010,0010'
        @initials = tags['0010,0010'][:value] unless tags['0010,0010'][:value].blank?
      end 
      rescue Exception => msg 
          v_error = msg.to_s   
          #messed up dicom header?
       end
    end
    
    return @initials
  end  
  
  def scanner_source_from_dicom_info 
    # this used to be coming from metamri, but the metamri scanner_source stopped working with rails 5
     @scanner_source ||nil
     return @scanner_source unless @scanner_source.blank?
     
     image_datasets.each do |dataset|
       tags = dataset.dicom_taghash 
       unless tags.blank?  
          if !tags['0008,0080'].blank? and tags['0008,0080'] != '0008,0080'  
               v_scanner_source = tags['0008,0080'][:value].to_s
             return v_scanner_source unless v_scanner_source.blank?
          end
        end
     end
  end
  
  def assign_enrollments
    puts enum = infer_enrollments
    unless enum.blank?
      e = Enrollment.find_or_create_by_enumber(enum)
      puts e.enumber
      enrollments << e
    end
  end
    
  
  def infer_enrollments
    if aic = rmr_aiclike?
      study = ''
    elsif rmr_datelike?
      study = ''
    elsif rmr_digits.length == 4
      study = rmr_number_enum
    else
      study = rmr_study
    end
    study ||= ''
    study.downcase!
    guess = (study.present? && normed_rmr_digits.present?) ? study + normed_rmr_digits : ''
    # {:rmr => rmr, :guess => guess, :enrollments_list => enrollments_list, :best => enrollments_list.present? ? enrollments_list : guess}
  end
  
  def rmr_agreement(list, guess)
    list.include?(guess) ? true : false
  end
  
  def rmr_aiclike?
    match = /aic(\d+)/i.match(rmr)
    match[1] if match
  end
  
  def rmr_datelike?
    return false unless rmr_digits.length > 4
    begin
      date = case rmr_digits
      when /^(\d{1,2})(\d{1,2})(\d{2})$/  then
        Date.civil($3.to_i + 2000, $1.to_i, $2.to_i)
      when /^(\d{1,2})(\d{1,2})(\d{4})$/  then
        Date.civil($3.to_i, $1.to_i, $2.to_i)
      else
         Date.parse(rmr_digits)    #this probably isn't working in 1.9.3, but rmr's not coming thru with dates
        # might work, not sure of date format
        # Date.strptime(rmr_digits,'%Y%m%d')
      end
    
      (1990...Date.today.year).include? date.year
    rescue ArgumentError
      false
    end
    
  end
  
  
  def rmr_study
    match = /([a-z]+)\d*/.match(rmr)
    # Egad, this is ghastly - Hard-code our scanner tech's initials.
    match = /(?:RMR)?(?:MA)?(?:RF)?([A-z]{3})(?:MRI)?/.match(rmr) unless match
    match ? match[1] : ''
  end
  
  def rmr_number_enum
    case rmr_digits.first.to_i
    when 1 then
      return 'tbi'
    when 2   then
      return 'alz'
    when 4   then
      return 'pc'
    else
      return nil
    end
  end
  
  def match_by_rmr_digits?(mri_scan)
    other_match = /(\d+)/.match(mri_scan.study_rmr)
    other_digits = other_match ? other_match[1] : ''
    sorted_digits = [rmr_digits, other_digits].sort_by(&:size)
    # Ensure that the index of an empty string is nil, not 0.
    index = other_digits.blank? ? nil : sorted_digits[1].index(sorted_digits[0])
    [index, rmr_digits, other_digits]
  end
  
  def rmr_digits
    /(\d+)/.match(rmr) ? /(\d+)/.match(rmr)[1] : ''
  end
  
  def normed_rmr_digits
    rmr_digits.length == 4 ? rmr_digits[1..-1] : rmr_digits
  end
  
  def spaceship_message(mri_scan)
    "%s <=> %s (%.3f)" % [rmr, mri_scan.study_rmr]
  end
  
  def get_base_path()  # this is a duplicate of vgroup model function --- need a common location
  	# look for mount to adrc image server - different on linux vs mac os , and different on mac os delending on login order
  	# check for
  	# Linux /home/USER/adrcdata,   /Data/vtrak1   
  	#Mac  /Volumnes/team*  /Volumnes/team*/preprocessed   /Volumnes/team*/raw
  	base_path =""
  	#user = ENV['USER']
    # 
    # if File.directory?("/Volumes/team")
    #    base_path ="/Volumes/team"
    # elsif File.directory?("/Volumes/team-1")
    #    base_path ="/Volumes/team-1"
    # elsif File.directory?("/Volumes/team-2")
    #    base_path ="/Volumes/team-2" 
    # elsif File.directory?("/Volumes/team-3")
    #    base_path ="/Volumes/team-3"
    #     elsif File.directory?("/Volumes/team-4")
    #        base_path ="/Volumes/team-4"
    #     elsif File.directory?("/Volumes/team-5")
    #        base_path ="/Volumes/team-5"
    #     elsif File.directory?("/Volumes/team-6")
    #        base_path ="/Volumes/team-6"
    # else
  		base_path ="/mounts/data"	
    # end

  	return base_path
  end
  
  # Run before validations. Fixes the many-to-many association between visits
  # and enrollments from the nested_attributes enrollment_params hash passed in
  # by the controller. This prevents duplicate many-to-many records and looks up
  # the correct enrollment instead of creating a new one or updating one from a
  # previous scope.
  # 
  # 1) Clear out old enrollments.
  # 2) Look up existing Enrollments and EnrollmentVisitMemberships
  # 3) If the enrollment doesn't exist yet or is not linked to this visit,
  #    add it back into the enrollments array.  That way all enrollments 
  #    will be properly validated and linked.
  # 
  # From the Rails Rdoc when using nested attributes: 
  # If the hash contains an id key that matches an already associated record,
  # the matching record will be modified This means that if an id is present
  # for nested attributes, it will try to find the old record, but it will
  # only do so within the old scope. What we want is to replace the old
  # records with new ones.
  def lookup_enrollments  
    enrollments_from_params = enrollments.dup
    #enrollments.clear   
    enrollments = []  #????
    enrollments_from_params.each do |enrollment_from_params|
      #enrollment = Enrollment.find_or_initialize_by_enumber(enrollment_from_params.enumber)    
      enrollment = Enrollment.find_or_initialize_by(enumber: enrollment_from_params.enumber)
      unless enrollment.valid?
        errors.add(:enrollments, "Enrollment invalid for #{enrollment.enumber}")
        raise ActiveRecord::Rollback
      end
      # 
      # If the enrollment was marked for destruction, get rid of the 
      # linking membership.  (Not the enrollment itself).
      # Otherwise, add the enrollment to the list of enrollments for this visit.
      
      if enrollment_from_params.marked_for_destruction?
##    the enrollment_visit_membership seems to be deleted --- not sure why or how
## this line was causing an error -- when removed the error went away and the delete occurred
 #  enrollment_visit_memberships.where(:enrollment_id => enrollment.id, :visit_id => id).delete   
      else
        enrollments << enrollment        
      end
     

        
      # If there's not already an existing membership between these two, create one.
      # If the membership already exists, we don't have to worry about it, so don't
      # even add it back into enrollments.
      # elsif memberships.empty?
      #   # Since the enrollment has been found new, we need to do some monkey-ing
      #   # around to rebuild the has-and-belongs-to-many relation.
      #   enrollments[i] = enrollment
      #   enrollments[i].visits << self 
      # elsif enrollment.marked_for_deletion?
      #   memberships.first.delete        
      # end

    end

  end
  
  def update_compiled_at_date
    self.compiled_at = Time.zone.now
  end

  def self.csv_download(visits, include_options = {})
    visits.report_table(:all, 
      :except => Visit::EXCLUDED_REPORT_ATTRIBUTES, 
      :include => include_options
    ).to_csv
  end
  
  def self.csv_download_limit(visits, include_options = {}, exclude_options = {})
    visits.report_table(:all, 
      :except => exclude_options, 
      :include => include_options
    ).to_csv
  end

end
