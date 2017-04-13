class CgTn < ActiveRecord::Base
   has_many :cg_tn_cns,:dependent => :destroy
   has_and_belongs_to_many :users
   
   has_attached_file :datadictionary ,:url => "/system/datadictionaries/:id/original/:filename",:path => ":rails_root/public/system/datadictionaries/:id/original/:filename" 
   validates_attachment_size :datadictionary, :less_than => 50.megabytes
   has_attached_file :datadictionary2,:url => "/system/datadictionary2s/:id/original/:filename",:path => ":rails_root/public/system/datadictionary2s/:id/original/:filename" 
   validates_attachment_size :datadictionary2, :less_than => 50.megabytes 
    # do_not_validate_attachment_file_type :datadictionary 
   #do_not_validate_attachment_file_type :datadictionary2  
   validates_attachment_content_type :datadictionary,  :matches => [/xls\Z/, /xlsx\Z/, /pdf\Z/, /zip\Z/],:not =>[]  
   #:content_type => ["application/vnd.ms-excel; charset=binary","application/pdf","application/xls","application/vnd.ms-excel","application/vnd.openxmlformats-officedocument.spreadsheetml.sheet","application/zip"]
   validates_attachment_content_type :datadictionary2,  :matches => [/xls\Z/, /xlsx\Z/, /pdf\Z/, /zip\Z/] ,:not =>[]  
   # :content_type => ["application/vnd.ms-excel; charset=binary","application/pdf","application/xls","application/vnd.ms-excel","application/vnd.openxmlformats-officedocument.spreadsheetml.sheet","application/zip"]

end
