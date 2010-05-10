class Visit < ActiveRecord::Base
  default_scope :order => 'date DESC', :include => [:scan_procedure, {:enrollment => :participant} ]
  
  validates_presence_of :date, :scan_procedure
  validates_uniqueness_of :rmr, :case_sensitive => false
    
  belongs_to :scan_procedure
  has_many :image_datasets, :dependent => :destroy
  has_many :log_files
  belongs_to :user
  belongs_to :enrollment
  has_one :participant, :through => :enrollment
  has_one :neuropsych_session
  belongs_to :created_by, :class_name => "User"
  
  accepts_nested_attributes_for :enrollment
  
  named_scope :complete, :conditions => { :compile_folder => 'yes' }
  named_scope :incomplete, :conditions => { :compile_folder => 'no' }
  named_scope :recently_imported, :conditions => ["visits.updated_at > ?", DateTime.now - 1.week]
  named_scope :assigned_to, lambda { |user_id|
    { :conditions => { :user_id => user_id } }
  }
  named_scope :in_scan_procedure, lambda { |protocol_id|
    { :conditions => { :scan_procedure_id => protocol_id } }
  }  


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
        elsif k == 'enum'
          enum_conditions = []
          v.each do |enum|
            enum_conditions << 'enrollments.enum = ?' 
            qualifiers << enum
          end
          conditions << "(" + enum_conditions.join(" OR ") + ")"
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
    
    visit = Visit.find_or_initialize_by_rmr(v.attributes_for_active_record)
    visit.update_attributes(v.attributes_for_active_record) unless visit.new_record?
    visit.scan_procedure = sp
    
    thumbnails = []
    v.datasets.each do |dataset|
      begin
        # Note: Using Metamri#RawImageDatasetThumbnail Directly
        begin
          thumbnails << File.open(RawImageDatasetThumbnail.new(dataset).thumbnail)
          visit.image_datasets.build(dataset.attributes_for_active_record(:thumb => thumbnails.last))
        rescue StandardError, ScriptError => e
          puts e
          visit.image_datasets.build(dataset.attributes_for_active_record)  
        end
      rescue Exception => e
        puts "Error building image_dataset. #{e}"
        raise e
      end
    end
    
    visit.created_by = created_by
    puts visit.image_datasets
    visit.save
    
    # thumbnails.each { |thumb| thumb.close }

    return visit

  end

end