class ProtocolRole < ActiveRecord::Base
 # has_and_belongs_to_many :users  --- then expectes table protocol_roles_users
  belongs_to :user
 #  has_and_belongs_to_many :protocols  --- then expectes table protocol_roles_protocols
    belongs_to :protocol
   attr_accessible   :codename, :description, :protocol_id, :user_id, :role
end
