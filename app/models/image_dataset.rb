class ImageDataset < ActiveRecord::Base
  
  default_includes = [:image_dataset_quality_checks, :analysis_memberships, {:visit => {:enrollment => :participant}}]
  default_scope :include => default_includes, :order => 'image_datasets.timestamp ASC, image_datasets.path ASC'
  
  named_scope :excluded, :conditions => ['analysis_memberships.excluded = ?', true]
  
  has_many :image_comments
  belongs_to :visit
  has_many :analysis_memberships
  # has_many :analyses, :through => :analysis_memberships
  has_many :image_dataset_quality_checks, :dependent => :destroy
  has_one :log_file
  
  has_attached_file :thumbnail, :styles => { :large => "900x900>", :medium => "300x300>", :thumb => "100x100>" }

  
  validates_presence_of :path, :scanned_file
  #validates_uniqueness_of :dataset_identifier
  
  has_many :physiology_text_files
  accepts_nested_attributes_for :physiology_text_files, :allow_destroy => true

  def rep_time_hundredths
    (100 * rep_time).round / 100.0
  end
  
  def excluded_by_any_analyses?
    self.analysis_memberships.each do |am|
      return true if am.excluded?
    end
    return false
  end
  
  def path_basename
    File.basename(path)
  end
  
  def details_hash
    { :Path => path,
      :Scanned_file => scanned_file,
      :Glob_pattern => glob,
      :Bold_reps => bold_reps,
      :Rep_time => rep_time_hundredths,
      :Slices_per_volume => slices_per_volume 
    }
  end
  
  def visit_details_hash
    visit.nil? ? nil : {
      :visit_date => visit.date,
      :scan_procedure => (visit.scan_procedure.codename rescue nil),
      :Scan_number => visit.scan_number,
      :Enum => (visit.enrollment.enum rescue nil),
      :Initials => visit.initials,
      :RMR_Number => visit.rmr,
      :Assignee => (visit.user.login rescue nil),
      :Directory_Path => visit.path
    }
  end
  
  def participant_details_hash
    if visit.blank? or visit.enrollment.blank?
      return nil
    else
      e = visit.enrollment
      p = e.participant.blank? ? nil : e.participant
      return { :birth_year => (p.dob.year rescue nil),
        :gender => (p.gender_prompt rescue nil),
        :wrap_number => ( p.wrapnum rescue nil),
        :education_years => (p.ed_years rescue nil),
        :apoe_status => (p.genetic_status rescue nil)
      }
    end
  end
  
  def dataset_identifier
    File.join(path, scanned_file)
  end
  
  def find_by_dataset_identifier(path, scanned_file)
    self.class.find()
  end
  
  def create_thumbnail
    # Only available for Dicoms - Done through glob.
    raise StandardError, "#{scanned_file} is not a DICOM image." if (scanned_file =~ /P.*\.7/ || scanned_file =~ /^I\./ || glob == nil)
    
    if File.exist?(File.join(path, scanned_file))
      original_zip_status = false
      file_to_scan = File.join(path, scanned_file)
    elsif File.exist?("#{File.join(path, scanned_file)}.bz2") # Then scanned file is currently zipped
      original_zip_status = true
      file_to_scan = Pathname.new("#{File.join(path, scanned_file)}.bz2").local_copy.to_s
    else
      raise StandardError, "Could not find file #{File.join(path, scanned_file)} on filesystem."
    end

    ds = RawImageDataset.new(path, RawImageFile.new(file_to_scan))
    
    thumbnail = RawImageDatasetThumbnail.new(ds).create_thumbnail
    raise StandardError, "Could not create thumbnail for #{File.join(path, scanned_file)}" unless File.exists?(thumbnail)
    
    return thumbnail
  end
  
  private
  
  def validate 
    db_result = self.class.find(:first, :conditions => ['path = ? AND scanned_file = ?', self.path, self.scanned_file])
    puts db_result
    unless db_result.blank? # No Image Dataset was found with the dataset identifier, it's ok to save this.
      unless db_result == self # Ensure uniqueness.
        errors.add_to_base('Dataset path and file must be unique.') 
      end
    end
  end 
  
  
end
