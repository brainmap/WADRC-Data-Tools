class Question < ActiveRecord::Base
   has_many :question_scan_procedures, :dependent => :destroy
   has_many :questionform_questions, :dependent => :destroy
end
