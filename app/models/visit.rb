class Visit < ActiveRecord::Base
  # default_scope :order => 'date DESC', :include => [:scan_procedure, {:enrollment => :participant} ]
  
  validates_presence_of :date, :scan_procedure
  # Allow the DICOM UID to be blank for visits without Scans
  validates_uniqueness_of :dicom_study_uid, :case_sensitive => false, :unless => Proc.new {|visit| visit.dicom_study_uid.blank?}
    
  belongs_to :scan_procedure
  has_many :image_datasets, :dependent => :destroy
  has_many :log_files
  belongs_to :user
  belongs_to :enrollment
  has_one :participant, :through => :enrollment
  has_one :neuropsych_session
  belongs_to :created_by, :class_name => "User"
  
  accepts_nested_attributes_for :enrollment
  
  scope :complete, where(:compile_folder => "yes")
  scope :incomplete, where(:compile_folder => "no")
  scope :recently_imported, where(:created_at.gt => 1.week.ago)
  scope :assigned_to, lambda { |user_id|
    { :conditions => { :user_id => user_id } }
  }
  scope :in_scan_procedure, lambda { |protocol_id|
    { :conditions => { :scan_procedure_id => protocol_id } }
  }  
  
  paginates_per 5
  
  acts_as_reportable


  def week
    self.date.beginning_of_week
  end
  
  def month
    self.date.beginning_of_month
  end
  
  def Visit.find_by_search_params(params)
    conditions = []; qualifiers = []
    
    params.each_pair do |k,v|
      unless v.empty?
        if 'rmr path'.include?(k)
          conditions << "#{k} LIKE ?"
          qualifiers << "%#{v}%"
        elsif k == 'enumber'
          enumber_conditions = []
          v.each do |enumber|
            enumber_conditions << 'enrollments.enumber = ?' 
            qualifiers << enumber
          end
          conditions << "(" + enumber_conditions.join(" OR ") + ")"
        elsif k == 'scan_procedure'
          scan_procedure_conditions = []
          v.each do |codename|
            scan_procedure_conditions << 'scan_procedures.codename = ?'
            qualifiers << codename
          end
          conditions << "(" + scan_procedure_conditions.join(" OR ") + ")"
        else
          conditions << "#{k} = ?"
          qualifiers << v
        end
      end
    end
    
    find_conditions = [conditions.join(' AND '), *qualifiers]
    
    Visit.find(:all, :conditions => find_conditions)
  end
  
  def self.scanner_sources
    find_by_sql('select DISTINCT(scanner_source) from visits').map { |v| v.scanner_source }.compact
  end
  
  def self.create_or_update_from_metamri(v, created_by = nil)
    created_by ||= User.first
    
    sp = ScanProcedure.find_or_create_by_codename(v.scan_procedure_name)
    
    # We need to handle Old Studies involving GE I-Files, which don't have any true UID
    visit_attrs = v.attributes_for_active_record.merge(:scan_procedure => sp)
    if visit_attrs[:dicom_study_uid]
      visit = Visit.find_or_initialize_by_dicom_study_uid(visit_attrs)
    else
      visit = Visit.find_or_initialize_by_rmr(visit_attrs)
    end
    visit.update_attributes(visit_attrs) unless visit.new_record?
    
    # For each dataset in the RawVisitDataDirectory...
    v.datasets.each do |dataset|
      begin
        # Skip directories that are links.
        next if File.symlink? dataset.directory
        
        # Initialize Thumbnail (or nil)
        # Note: Using Metamri#RawImageDatasetThumbnail Directly
        begin 
          thumb = File.open(RawImageDatasetThumbnail.new(dataset).thumbnail)
        rescue StandardError, ScriptError => e
          logger.debug e
          thumb = nil
        end

        # Test to see if this dataset already exists and grab it if so, otherwise build it fresh.
        data = visit.image_datasets.select {|ds| ds.dicom_series_uid == dataset.dicom_series_uid }.first
        attrs = dataset.attributes_for_active_record(:thumb => thumb)
        
        unless data.blank?
          data.update_attributes(attrs)
        else
          visit.image_datasets.build(attrs)  
        end
      rescue Exception => e
        puts "Error building image_dataset. #{e}"
        raise e
      end
    end
    
    visit.created_by = created_by
    visit.save    

    return visit

  end
  
  def age_at_visit
    pp "age", age_from_dicom_info
    return age_from_dicom_info[:age] unless age_from_dicom_info[:age].blank?

    unless enrollment.nil?
      unless enrollment.participant.nil?
        unless enrollment.participant.dob.nil?
          participant_dob = enrollment.participant.dob
        end
      end
    end
    
    dob = age_from_dicom_info[:dob] ||= participant_dob

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

end
