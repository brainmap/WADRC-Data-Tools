class RecruitmentGroup < ActiveRecord::Base
  belongs_to :study
  has_many :enrollments
end
