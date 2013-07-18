begin
  require 'metamri/raw_image_dataset_thumbnail'
rescue LoadError => e
  puts "Problem loading Metamri for Thumbnail Creation. #{e}"
end

class ImageDataset < ActiveRecord::Base
  EXCLUDED_REPORT_ATTRIBUTES = [:dicom_taghash, :created_at, :updated_at, :visit_id, :thumbnail_file_name, :thumbnail_file_size, :thumbnail_content_type, :thumbnail_updated_at]
  
  # default_includes = [:image_dataset_quality_checks, :analysis_memberships, {:visit => {:enrollment => :participant}}]
  default_scope :order => 'image_datasets.timestamp ASC, image_datasets.path ASC' # :include => default_includes, 
  
  scope :excluded, :conditions => ['analysis_memberships.excluded = ?', true]
  
  has_many :image_comments
  belongs_to :visit
  has_many :analysis_memberships
  # has_many :analyses, :through => :analysis_memberships
  has_many :image_dataset_quality_checks, :dependent => :destroy
  has_one :log_file
  # Allow the DICOM UID to be blank for PFile Datasets, otherwise enforce uniqueness
  validates_uniqueness_of :dicom_series_uid, :case_sensitive => false, :unless => Proc.new {|dataset| dataset.dicom_series_uid.blank?}, :message => "Series UID must be unique."
  
  has_attached_file :thumbnail, 
    :styles => { :large => "900x900>", :medium => "300x300>", :thumb => "100x100" },
    :default_url => "/images/missing-sag.gif"

  
  validates_presence_of :scanned_file
  # validates_uniqueness_of :dataset_identifier
  
  has_many :physiology_text_files
  accepts_nested_attributes_for :physiology_text_files, :allow_destroy => true
  
  serialize :dicom_taghash
  attr_unsearchable :dicom_taghash
  
  delegate :participant, :to => :visit
  
  # Note: As of 8/24/2011, default excludes (:except => :id) are not working.
  # Use the Class Constant ImageDataset::EXCLUDED_REPORT_ATTRIBUTES instead.
  acts_as_reportable
  
  # Note - Path is NOT unique (due to PFiles)
  # validates :path, :filesytem_format => true

  def rep_time_hundredths
    # if !rep_time.blank?  # put default 0 in the db instead
    (100 * rep_time).round / 100.0
    # else
    #  return 0
    # end
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
      :enumber => (visit.enrollment.enumber rescue nil),
      :Initials => visit.initials,
      :RMR_Number => visit.rmr,
      :Assignee => (visit.user.username rescue nil),
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
    raise StandardError, "#{scanned_file} is not a DICOM image." if dicom?
    
    if File.exist?(File.join(path, scanned_file))
      original_zip_status = false
      file_to_scan = File.join(path, scanned_file)
    elsif File.exist?("#{File.join(path, scanned_file)}.bz2") # Then scanned file is currently zipped
      original_zip_status = true
      file_to_scan = Pathname.new("#{File.join(path, scanned_file)}.bz2").local_copy(Dir.mktmpdir).to_s
    else
      raise StandardError, "Could not find file #{File.join(path, scanned_file)} on filesystem."
    end
    
    ds = RawImageDataset.new(path, RawImageFile.new(file_to_scan))
    png_path = RawImageDatasetThumbnail.new(ds).create_thumbnail
    tf = File.open(png_path)
    self.thumbnail = tf
    raise(StandardError, "Could not create thumbnail for #{File.join(path, scanned_file)}") unless File.exists?(png_path)
    return png_path
  end
  
  def dicom?
    !pfile? and !geifile? and !(glob == nil)
  end
  
  def pfile?
    scanned_file =~ /P.*\.7/
  end
  
  def geifile?
    scanned_file =~ /^I\./
  end
  
  def self.csv_download(datasets, include_options = {})
    datasets.report_table(:all, 
      :except => ImageDataset::EXCLUDED_REPORT_ATTRIBUTES, 
      :include => include_options
    ).to_csv
  end
  
  def dataset_uid
    dicom_series_uid || image_uid
  end
  
  def self.report
    File.open('dump.csv', 'w') do |f|
      f.puts report_table(:all,
        :except => [:timestamp, :created_at, :updated_at, :id, :rep_time, :glob, :thumbnail_file_name, :bold_reps, :thumbnail_file_size, :thumbnail_content_type, :thumbnail_updated_at, :slices_per_volume, "scanned_file", "visit_id"], 
        :conditions => "series_description LIKE '%DTI%' AND series_description NOT LIKE '%GW3D%'", 
        # :limit => 500,
        :include => { 
          :visit => { :methods => :age_at_visit, :only => [:scanner_source, :date], :include => {
            :enrollment => {:only => [:enumber], :include => { 
              :participant => { :methods => :genetic_status, :only => [:gender, :wrapnum, :ed_years], :conditions => "wrapnum IS NOT NULL OR wrapnum <> ''" } 
            }}
          }} 
        }
      ).to_csv
    end
  end

end
