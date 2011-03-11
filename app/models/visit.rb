class Visit < ActiveRecord::Base
  RADIOLOGY_OUTCOMES = %w{no Nm A-F A-NF n/a}
  PROGRESS_CHOICES = %w{no yes n/a}
  
  # default_scope :order => 'date DESC', :include => [:scan_procedure, {:enrollment => :participant} ]
  default_scope :order => 'date DESC'
  
  validates_presence_of :date
  # Allow the DICOM UID to be blank for visits without Scans
  validates_uniqueness_of :dicom_study_uid, :case_sensitive => false, :unless => Proc.new {|visit| visit.dicom_study_uid.blank?}
  
  has_and_belongs_to_many :scan_procedures
  has_many :image_datasets, :dependent => :destroy
  has_many :log_files
  belongs_to :user
  has_one :participant, :through => :enrollment
  has_one :neuropsych_session
  belongs_to :created_by, :class_name => "User"
  
  validates_inclusion_of :radiology_outcome, :in => RADIOLOGY_OUTCOMES
  validates_inclusion_of :transfer_mri, :transfer_pet, :conference, :compile_folder, :in => PROGRESS_CHOICES
  
  has_many :enrollment_visit_memberships
  has_many :enrollments, :through => :enrollment_visit_memberships, :uniq => true
  accepts_nested_attributes_for :enrollments, :reject_if => :all_blank, :allow_destroy => true
  before_validation :lookup_enrollments
    
    
  scope :complete, where(:compile_folder => "yes")
  scope :incomplete, where(:compile_folder => "no")
  scope :recently_imported, where(:created_at.gt => 1.week.ago)
  scope :assigned_to, lambda { |user_id|
    { :conditions => { :user_id => user_id } }
  }
  scope :in_scan_procedure, lambda { |protocol_id|
    { :conditions => { :scan_procedure_id => protocol_id } }
  }  
  
  paginates_per 50
  
  delegate :enumber, :to => :enrollment, :prefix => true
  
  acts_as_reportable


  def week
    self.date.beginning_of_week
  end
  
  def month
    self.date.beginning_of_month
  end
  
  def self.scanner_sources
    find_by_sql('select DISTINCT(scanner_source) from visits').map { |v| v.scanner_source }.compact
  end
  
  def enrollment_list
    enrollments.collect {|enroll| enroll.enumber }.join(", ")
  end
  
  # V is a Metamri VisitRawDataDirectory Object that has already been created 
  # and v.scan 'ed, so it has datasets.
  def self.create_or_update_from_metamri(v, created_by = nil)
    created_by ||= User.first
    
    sp = ScanProcedure.find_or_create_by_codename(v.scan_procedure_name)
    
    # Build an ActiveRecord Visit object using available attributes from metamri.
    # We need to handle Old Studies involving GE I-Files, which don't have any true UID
    visit_attrs = v.attributes_for_active_record.merge(:scan_procedure_ids => [sp.id])
    if visit_attrs[:dicom_study_uid]
      visit = Visit.find_or_initialize_by_dicom_study_uid(visit_attrs)
    else
      visit = Visit.find_or_initialize_by_rmr(visit_attrs)
    end
    visit.attributes.merge!(visit_attrs)
    visit.scan_procedures = [sp]

    
    # We have to zip up the metamri datasets and the activerecord visit datasets
    # For each dataset in the VisitRawDataDirectory...
    v.datasets.each do |dataset|
      begin
        # Skip directories that are links.
        next if File.symlink? dataset.directory
        
        # Initialize Thumbnail (or nil)
        # Note: Using Metamri#RawImageDatasetThumbnail Directly
        metamri_attr_options = {}
        begin
          metamri_attr_options[:thumb] = File.open(RawImageDatasetThumbnail.new(dataset).thumbnail)
        rescue StandardError, ScriptError => e
          logger.debug e
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
        data = ImageDataset.where(:dicom_series_uid => dataset.dicom_series_uid).first
        meta_attrs = dataset.attributes_for_active_record(metamri_attr_options)
        
        # If the ActiveRecord Visit (visit) has a dataset that already matches the metamri dataset (dataset) on dicom_series_uid, then use it and update its params.  Otherwise, build a new one.
        unless data.blank? # AKA data.kind_of? ImageDataset
          logger.debug "updating dataset #{data.id} with new metamri attributes"
          data.attributes.merge!(meta_attrs)
          if data.valid?
            visit.image_datasets << data
          else
            raise StandardError, "Image Dataset #{data.path} not valid: #{e}"
          end
        else
          logger.debug "building fresh visit.image_datasets.build(#{meta_attrs})"
          visit.image_datasets.build(meta_attrs)  
        end
        

      rescue Exception => e
        puts "Error building image_dataset. #{e}"
        raise e
      ensure
        metamri_attr_options[:thumb].close if metamri_attr_options.kind_of? File
      end
    end
    
    visit.created_by = created_by
    visit.save

    return visit

  end
  
  def age_at_visit
    return age_from_dicom_info[:age] unless age_from_dicom_info[:age].blank?

    unless enrollments.blank?
      enrollments.each do |enrollment|
        unless enrollment.participant.blank?
          unless enrollment.participant.dob.blank?
            participant_dob = enrollment.participant.dob
          end
        end
      end
    end
    
    dob = age_from_dicom_info[:dob] ||= participant_dob ||= nil

    unless dob.blank?
      date.year - dob.year - ((date.month > dob.month || (date.month == dob.month && date.day >= dob.day)) ? 0 :1 ) unless dob.nil?
    end
  end
  
  def age_from_dicom_info
    @age_info ||= {}
    return @age_info unless @age_info.blank?
    
    image_datasets.each do |dataset|
      if tags = dataset.dicom_taghash
        @age_info[:age] = tags['0010,1010'][:value].blank? ? nil : tags['0010,1010'][:value].to_i
        @age_info[:dob] = tags['0010,0030'][:value].blank? ? nil : begin DateTime.parse(tags['0010,0030'][:value]) rescue ArgumentError; nil end
      end
    end
    return @age_info
  end
  
  def find_first_dicom_study_uid
    uid = ''
    image_datasets.each do |dataset|
      tags = dataset.dicom_taghash
      unless tags.blank?
        uid = tags['0020,000D'][:value] unless tags['0020,000D'][:value].blank?
      end
    end
    return uid
  end
  
  def initials
    initials_from_dicom_info
  end
  
  def initials_from_dicom_info
    @initials ||= ''
    return @initials unless @initials.blank?
    
    image_datasets.each do |dataset|
      if tags = dataset.dicom_taghash
        @initials = tags['0010,0010'][:value] unless tags['0010,0010'][:value].blank?
      end
    end
    
    return @initials
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
    original_enrollments = enrollments.dup
    enrollments.clear
    original_enrollments.each_with_index do |original_enrollment, i|
      enrollment = Enrollment.find_or_create_by_enumber(original_enrollment.enumber)
      unless enrollment.valid?
        errors.add(:enrollments, "Enrollment invalid")
        raise ActiveRecord::Rollback
      end
      memberships = enrollment_visit_memberships.where(:enrollment_id => enrollment.id)
      # If the enrollment was marked for destruction, get rid of the 
      # linking membership.  (Not the enrollment itself).
      if original_enrollment.marked_for_destruction?
        memberships.each {|membership| membership.delete}
      # If there's not already an existing membership between these two, create one.
      # If the membership already exists, we don't have to worry about it, so don't
      # even add it back into enrollments.
      elsif memberships.empty?
        # Since the enrollment has been found new, we need to do some monkey-ing
        # around to rebuild the has-and-belons-to-many relation.
        enrollments[i] = enrollment
        enrollments[i].visits << self 
      elsif enrollment.marked_for_deletion?
        memberships.first.delete        
      end

    end

  end

end
