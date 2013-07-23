class Schedule < ActiveRecord::Base
  has_many :scheduleruns
  has_and_belongs_to_many :users

end
