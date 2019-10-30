begin
  require 'metamri/raw_image_dataset_thumbnail'
rescue LoadError => e
  puts "Problem loading Metamri for Thumbnail Creation. #{e}"
end

class ImageDataset < ActiveRecord::Base
  EXCLUDED_REPORT_ATTRIBUTES = [:dicom_taghash, :created_at, :updated_at, :visit_id, :thumbnail_file_name, :thumbnail_file_size, :thumbnail_content_type, :thumbnail_updated_at]
  
  # default_includes = [:image_dataset_quality_checks, :analysis_memberships, {:visit => {:enrollment => :participant}}]
  #default_scope :order => 'image_datasets.timestamp ASC, image_datasets.path ASC' # :include => default_includes, 
   default_scope { order(timestamp: :asc,path: :asc) }   

  ###scope :excluded, :conditions => ['analysis_memberships.excluded = ?', true] 
  scope :excluded, -> { where('analysis_memberships.excluded = ?', true) }
  
  has_many :image_comments
  belongs_to :visit
  has_many :analysis_memberships  , :class_name => 'AnalysisMembership'
  #has_many :analyses, :through => :analysis_memberships
  has_many :image_dataset_quality_checks, :dependent => :destroy  
  has_many :mriscantasks,:dependent => :destroy
  has_one :log_file
  # Allow the DICOM UID to be blank for PFile Datasets, otherwise enforce uniqueness
  validates_uniqueness_of :dicom_series_uid, :case_sensitive => false, :unless => Proc.new {|dataset| dataset.dicom_series_uid.blank?}, :message => "Series UID must be unique."
  
  #has_attached_file :thumbnail, :default_url => "/images/missing-sag.gif"   #, was causing imagemah=gick error :styles => { :large => "900x900>", :medium => "300x300>", :thumb => "100x100" },  :default_url => "/images/missing-sag.gif" 
  has_attached_file :thumbnail,  default_url: "/images/missing-sag.gif" ,          #styles: { thumb: "100x100" },    STYLES CAUSING imagemagick error - not resizing? - no product and then not identifiaable
  :url => "/system/thumbnails/:id/original/:filename",:path => ":rails_root/public/system/thumbnails/:id/original/:filename"
  # problem with styles-paperclip-imagemagick resizing  - maybe its an imagemagick on mac issue?
  # changed ids page to display image as 100x100 using original   
  #styles: { large: "900x900>", medium: "300x300>", thumb: "100x100" },
 # do_not_validate_attachment_file_type :thumbnail  
  validates_attachment_content_type :thumbnail,  :matches => [/png\Z/, /png\[0\]\Z/,/jpeg\Z/, /jpg\Z/, /gif\Z/],:not =>[]  # :content_type => ["image/jpg", "image/jpeg", "image/png", "image/gif"] 
  validates_presence_of :scanned_file
  # validates_uniqueness_of :dataset_identifier  
  
  
  has_many :physiology_text_files
  accepts_nested_attributes_for :physiology_text_files, :allow_destroy => true
  
  attr_accessor :lock_default_scan_flag_parse  # virtual atrtribute - don't think this actually does anything except supressing an error
  
  serialize :dicom_taghash #, Hash      # added Hash # 20140324 hashed out Hash - ? 1.9.2 ruby? -- seems to work now
 #     attr_unsearchable :dicom_taghash    #   hashed out cai 20130926 -- used in old search ? meta_search, meta_where
  
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
      :Rep_time => (rep_time_hundredths rescue nil),
      :Slices_per_volume => slices_per_volume,
      :Mri_Coil_Name => mri_coil_name, 
      :Mri_Station_Name => mri_station_name,
      :Mri_Manufacturer_Model_Name => mri_manufacturer_model_name
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
    raise StandardError, "#{scanned_file} is not a DICOM image." if !dicom?
    if File.exist?(File.join(path, scanned_file))
      original_zip_status = false
      file_to_scan = File.join(path, scanned_file)
    elsif File.exist?("#{File.join(path, scanned_file)}.bz2") # Then scanned file is currently zipped
      original_zip_status = true
      file_to_scan = Pathname.new("#{File.join(path, scanned_file)}.bz2").local_copy(Dir.mktmpdir).to_s
    else
      raise StandardError, "Could not find file #{File.join(path, scanned_file)} on filesystem."
    end
    #ds = RawImageDataset.new(path, RawImageFile.new(file_to_scan))  
    #png_path = RawImageDatasetThumbnail.new(ds).create_thumbnail 

    #first, get the output path, and check that everything exists
    #if not, raise an error

    output_directory = Dir.mktmpdir
    default_name = self.series_description.escape_filename
    thumbnail_path = File.join(output_directory, default_name + '.png')

    thumbnail_path_expanded = File.expand_path(thumbnail_path)
    
    dcm = DICOM::DObject.read(file_to_scan)
    raise ScriptError, "Could not read dicom #{file_to_scan}" unless dcm.read_success
    v_call = "dcmj2pnm -v +Wi 1 --write-png #{file_to_scan} "+thumbnail_path_expanded
    v_results = %x[#{v_call}]
    puts "results= "+v_results
    puts "dicom_file= "+dicom_file.to_s
    puts "output_file= "+thumbnail_path_expanded

    raise(ScriptError, "Error creating thumbnail #{thumbnail_path_expanded}") unless File.exist?(thumbnail_path_expanded)

    tf = File.open(thumbnail_path_expanded)
    self.thumbnail = tf
    return thumbnail_path_expanded
  end

  def thumbnail_exists?
    return FileTest.file? self.thumbnail.path
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
        :except => [:timestamp, :created_at, :updated_at, :id, :rep_time, :glob, :thumbnail_file_name, :bold_reps, :thumbnail_file_size, :thumbnail_content_type, :thumbnail_updated_at, :slices_per_volume,:mri_station_name, :mri_manufacturer_model_name, :mri_coil_name,"scanned_file", "visit_id"], 
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
