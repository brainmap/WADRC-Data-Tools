class QDataForm < ActiveRecord::Base
  has_many  :q_datum
   belongs_to :user
end
