class EnrollmentVgroupMembership < ActiveRecord::Base
#  belongs_to :enrollment
#  belongs_to :vgroup
#  validates_uniqueness_of :enrollment_id, :scope => :vgroup_id, :message => "You're trying to duplicate a many-to-many relationship. The enrollment is already linked to the Visit. "
#  validates_presence_of :enrollment_id, :vgroup_id
end