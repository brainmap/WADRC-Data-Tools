class ImageDatasetQualityCheck < ActiveRecord::Base
  PASSING_STATUSES = Set.new(%w(complete pass))
  FAILING_STATUSES = Set.new( ["Incomplete","Mild","Moderate","Severe","Limited Activation","No activation","No pass"] )
  belongs_to :user
  belongs_to :image_dataset
  
  acts_as_reportable :methods => :failing_checks_list
  
  def failing_checks
    failing_checks = Set.new
    self.attribute_names.each do |name|
      unless name.blank?
        if FAILING_STATUSES.include?(self[name])
          failing_checks << name.capitalize.gsub("_", " ")
        end
      end
    end
    return failing_checks
  end
  
  def failing_checks_list
    failing_checks.to_a.join(', ')
  end

  def pass?
    failing_checks.empty?
  end

end
