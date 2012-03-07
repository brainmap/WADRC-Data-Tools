class Employee < ActiveRecord::Base
  belongs_to :lookup_status
  belongs_to :user
end
