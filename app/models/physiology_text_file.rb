class PhysiologyTextFile < ActiveRecord::Base
  belongs_to :image_dataset
  validates_uniqueness_of :filepath
  
  # validates_format_of :filepath, :with => /^\/Data\/vtrak1\/raw\//, :message => "must begin with '/Data/vtrak1/raw'"
  # not being used? wrong path even  causing error in startup  
  #Message from application: The provided regular expression is using multiline anchors (^ or $), which may present a security risk. Did you mean to use \A and \z, or forgot to add the :multiline => true option? (ArgumentError) 
  ### validates_format_of :filepath, :with => /^\/Volumes\/team*\/raw\//, :message => "must begin with '/Volumes/team*/raw'"

end
