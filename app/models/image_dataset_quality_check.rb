class ImageDatasetQualityCheck < ActiveRecord::Base
  PASSING_STATUSES = Set.new(%w(complete pass))
  FAILING_STATUSES = Set.new( ["Incomplete","Mild","Severe","No activation"] )
  belongs_to :user
  belongs_to :image_dataset
  
  def failing_checks
    failing_checks = Set.new
    self.attribute_names.each do |name|
      puts self[name]
      unless name.blank?
        if FAILING_STATUSES.include?(self[name])
          failing_checks << name
        end
      end
    end
    return failing_checks
  end

end
