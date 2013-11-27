class EnrollmentVisitMembership < ActiveRecord::Base
  belongs_to :enrollment
  belongs_to :visit
  validates_uniqueness_of :enrollment_id, :scope => :visit_id, :message => "You're trying to duplicate a many-to-many relationship."
  validates_presence_of :enrollment_id, :visit_id
end
