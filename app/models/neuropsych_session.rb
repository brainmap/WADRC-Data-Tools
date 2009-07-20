class NeuropsychSession < ActiveRecord::Base
  belongs_to :visit
  has_many :neuropsych_assessments
end
