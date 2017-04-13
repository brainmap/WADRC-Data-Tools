class Analysis < ActiveRecord::Base
  has_many :analysis_memberships, :dependent => :destroy
  has_many :image_datasets, :through => :analysis_memberships
  belongs_to :user
  belongs_to :image_search
  
  scope :created_by, lambda { |user_id|
    { :conditions => { :user_id => user_id } }
  }

  def analysis_memberships_attributes=(analysis_memberships_attributes)
    analysis_memberships_attributes.each do |analysis_membership_attributes|
      analysis_memberships.build(analysis_membership_attributes)
    end
  end
  
  def update_analysis_memberships_attributes=(update_analysis_memberships_attributes)
    update_analysis_memberships_attributes.each_pair do |key,attr_hash|
      analysis_memberships.find_by_id(key).update(attr_hash)
    end
  end
end
