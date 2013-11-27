class ImageComment < ActiveRecord::Base
  belongs_to :image_dataset
  belongs_to :user

  validates_presence_of :user
  validates_presence_of :image_dataset
  EXCLUDED_REPORT_ATTRIBUTES = [:id, :image_dataset_id,:created_at,:updated_at,:user_id]
    acts_as_reportable
end
