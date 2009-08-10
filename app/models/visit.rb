class Visit < ActiveRecord::Base
  default_scope :order => 'date DESC', :include => [:scan_procedure, {:enrollment => :participant} ]
  
  validates_presence_of :date, :scan_procedure
  validates_uniqueness_of :rmr, :case_sensitive => false
  
  belongs_to :scan_procedure
  has_many :image_datasets, :dependent => :destroy
  has_many :log_files
  belongs_to :user
  belongs_to :enrollment
  has_one :neuropsych_session
  
  named_scope :complete, :conditions => { :compile_folder => 'yes' }
  named_scope :incomplete, :conditions => { :compile_folder => 'no' }
  named_scope :recently_imported, :conditions => ["visits.created_at > ?", DateTime.now - 1.week]
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
end
