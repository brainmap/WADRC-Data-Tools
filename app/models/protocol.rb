class Protocol < ActiveRecord::Base
  has_many :protocol_roles
  has_many :scan_procedures
end
