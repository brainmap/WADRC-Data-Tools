class Questionform < ActiveRecord::Base
  
    has_many :questionform_questions, :dependent => :destroy
    has_many :questionform_scan_procedures, :dependent => :destroy
end
