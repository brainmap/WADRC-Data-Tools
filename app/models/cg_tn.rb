class CgTn < ActiveRecord::Base
   has_many :cg_tn_cns,:dependent => :destroy
   has_and_belongs_to_many :users
   
   has_attached_file :datadictionary
   validates_attachment_size :datadictionary, :less_than => 50.megabytes
   has_attached_file :datadictionary2
   validates_attachment_size :datadictionary2, :less_than => 50.megabytes
   validates_attachment_content_type :datadictionary, :content_type => ["application/pdf","application/xls","application/vnd.ms-excel","application/vnd.openxmlformats-officedocument.spreadsheetml.sheet","application/zip"]
validates_attachment_content_type :datadictionary2, :content_type => ["application/pdf","application/xls","application/vnd.ms-excel","application/vnd.openxmlformats-officedocument.spreadsheetml.sheet","application/zip"]

end
