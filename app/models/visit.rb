require 'metamri'

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
  
  #accepts_nested_attributes_for :enrollment
  
  named_scope :complete, :conditions => { :compile_folder => 'yes' }
  named_scope :incomplete, :conditions => { :compile_folder => 'no' }
  named_scope :recently_imported, :conditions => ["visits.updated_at > ?", DateTime.now - 1.week]
  named_scope :assigned_to, lambda { |user_id|
    { :conditions => { :user_id => user_id } }
  }
  named_scope :in_scan_procedure, lambda { |protocol_id|
    { :conditions => { :scan_procedure_id => protocol_id } }
  }
  
  def enrollment_enum
    enrollment.enum unless enrollment.blank?
  end
  
  def enrollment_enum=(enum)
  # Manually specify the Enum Validation as ending with at least 3 digit integers.
  # This doesn't use the enrollment validations, which is not great style, but it works.
    if enum =~ /.*\d{3,}/
      self.enrollment = Enrollment.find_or_create_by_enum(enum) unless enum.blank?
    end
  end
  
  
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
        if 'rmr enum path'.include?(k)
          conditions << "#{k} LIKE ?"
          qualifiers << "%#{v}%"
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
  
  def self.create_or_update_from_metamri(v)
    sp = ScanProcedure.find_or_create_by_codename(v.scan_procedure_name)
    
    visit = Visit.find_or_initialize_by_rmr(v.attributes_for_active_record)
    visit.update_attributes(v.attributes_for_active_record) unless visit.new_record?
    visit.scan_procedure = sp
    
    if visit.image_datasets.blank?
      v.datasets.each do |d|
        visit.image_datasets.build(d.attributes_for_active_record)
      end
    end
    
    visit.save
  end
  
  private
  
  def validate
    puts enrollment_enum
    if enrollment_enum.blank? 
      errors.add_to_base "Enum not valid; it must end with at least 3 digits."
    end
  end
end
