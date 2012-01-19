require 'digest/sha1'
class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :ldap_authenticatable,  :rememberable, :trackable,:registerable, :recoverable
  # removed :registerable, :recoverable, :validatable

  # prevents a user from submitting a crafted form that bypasses activation
  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me, :username, :first_name,:last_name, :initials

  # Virtual attribute for the unencrypted password
  attr_accessor :login

  validates_presence_of     :username, :email
#  validates_presence_of     :password,                   :if => :password_required?
#  validates_presence_of     :password_confirmation,      :if => :password_required?
  validates_length_of       :password, :within => 4..40, :if => :password_required?
  validates_confirmation_of :password,                   :if => :password_required?
  validates_length_of       :username,    :within => 3..40
  validates_length_of       :email,    :within => 3..100
  validates_uniqueness_of   :username, :email, :case_sensitive => false
  # before_save :encrypt_password

  has_many :analyses, :dependent => :destroy
  has_many :image_comments, :dependent => :destroy
  has_many :visits
  has_many :image_searches, :dependent => :destroy
  
  has_many :image_dataset_quality_checks
  has_many :protocol_roles, :dependent => :destroy
  

  
  def username_name
    "#{self.first_name} #{self.last_name} #{self.username}"
  end
  
  def username_name_role
    "#{self.role} #{self.first_name} #{self.last_name} #{self.username} "
  end
  # having trouble setting the returned array as an array, showing as a user. string
  # so just treating as string - joining array on ' ' to make string, then converting back to array after retrieval
  def view_low_scan_procedure_array
    var = set_edit_view_array('view_low_scan_procedure_array')
    "#{var}"
  end
  def edit_low_scan_procedure_array
      var = set_edit_view_array('edit_low_scan_procedure_array')
      "#{var}"
  end  
=begin # hiding calls since not using yet
  def admin_low_scan_procedure_array
       var = set_edit_view_array('admin_low_scan_procedure_array')
       "#{var}"
  end
  def view_medium_scan_procedure_array
    var = set_edit_view_array('view_medium_scan_procedure_array')
    "#{var}"
  end
  def edit_medium_scan_procedure_array
      var = set_edit_view_array('edit_medium_scan_procedure_array')
      "#{var}"
  end  
  def admin_medium_scan_procedure_array
       var = set_edit_view_array('admin_medium_scan_procedure_array')
       "#{var}"
  end
  def view_high_scan_procedure_array
    var = set_edit_view_array('view_high_scan_procedure_array')
    "#{var}"
  end
  def edit_high_scan_procedure_array
      var = set_edit_view_array('edit_high_scan_procedure_array')
      "#{var}"
  end 
=end 
  def admin_high_scan_procedure_array
       var = set_edit_view_array('admin_high_scan_procedure_array')
       "#{var}"
  end
  
  def view_low_protocol_array
         var = set_edit_view_array('view_low_protocol_array')
         "#{var}"
  end
  def edit_low_protocol_array
          var = set_edit_view_array('edit_low_protocol_array')
          "#{var}"
  end
=begin    # hiding calls since not using yet
  def admin_low_protocol_array
            var = set_edit_view_array('admin_low_protocol_array')
            "#{var}"
  end  
  def view_medium_protocol_array
         var = set_edit_view_array('view_medium_protocol_array')
         "#{var}"
  end
  def edit_medium_protocol_array
          var = set_edit_view_array('edit_medium_protocol_array')
          "#{var}"
  end
  def admin_medium_protocol_array
            var = set_edit_view_array('admin_medium_protocol_array')
            "#{var}"
  end
  
  def view_high_protocol_array
         var = set_edit_view_array('view_high_protocol_array')
         "#{var}"
  end
  def edit_high_protocol_array
          var = set_edit_view_array('edit_high_protocol_array')
          "#{var}"
  end
=end
  def admin_high_protocol_array
            var = set_edit_view_array('admin_high_protocol_array')
            "#{var}"
  end
  
  
    def set_edit_view_array(field)
      user = self
      # make list of roles
      @roles_in_pr  =  user.protocol_roles.find_by_sql("SELECT DISTINCT role from protocol_roles where user_id = "+(user.id).to_s)
      # loop thru each role

      # error where unioning null arrays 
      self[:view_low_scan_procedure_array] = [-1]
      self[:edit_low_scan_procedure_array] = [-1]
      self[:admin_low_scan_procedure_array] = [-1]
      self[:admin_high_scan_procedure_array] = [-1]

      self[:view_low_protocol_array] = [-1]
      self[:edit_low_protocol_array] = [-1]
      self[:edit_high_protocol_array] = [-1]
      self[:admin_low_protocol_array] = [-1]
      self[:admin_high_protocol_array] = [-1]
      
       @roles_in_pr.each do |p| 
          if p.role == "Edit_High"
            # loop thru protocols and grant perms 
             protocol_array = []
            @current_self_protocol = self.protocol_roles.find_by_sql("SELECT distinct protocol_id from protocol_roles where role = '"+p.role+"' and user_id = "+(self.id).to_s)
            @current_self_protocol.each do |p2|
              protocol_array << p2.protocol_id
              end
            self[:edit_high_protocol_array] = protocol_array
            protocol_list = protocol_array*","
            scan_procedure_array = []
            @current_self_scan_procedure = self.protocol_roles.find_by_sql("SELECT distinct id from scan_procedures where protocol_id in ("+protocol_list+") ")
            @current_self_scan_procedure.each do |p2|
              scan_procedure_array << p2.id
              end
            self[:edit_high_scan_procedure_array] = scan_procedure_array
          end

          if p.role == "Edit_Medium"
             # loop thru protocols and grant perms 
              protocol_array = []
             @current_self_protocol = self.protocol_roles.find_by_sql("SELECT distinct protocol_id from protocol_roles where role = '"+p.role+"' and user_id = "+(self.id).to_s)
             @current_self_protocol.each do |p2|
               protocol_array << p2.protocol_id
               end
             self[:edit_medium_protocol_array] = protocol_array
             protocol_list = protocol_array*","
             scan_procedure_array = []
             @current_self_scan_procedure = self.protocol_roles.find_by_sql("SELECT distinct id from scan_procedures where protocol_id in ("+protocol_list+") ")
             @current_self_scan_procedure.each do |p2|
               scan_procedure_array << p2.id
               end
             self[:edit_me3dium_scan_procedure_array] = scan_procedure_array
          end

          if p.role == "Edit_Low"
             # loop thru protocols and grant perms 
              protocol_array = []
             @current_self_protocol = self.protocol_roles.find_by_sql("SELECT distinct protocol_id from protocol_roles where role = '"+p.role+"' and user_id = "+(self.id).to_s)
             @current_self_protocol.each do |p2|
               protocol_array << p2.protocol_id
               end
             self[:edit_low_protocol_array] = protocol_array
             protocol_list = protocol_array*","
             scan_procedure_array = []
             @current_self_scan_procedure = self.protocol_roles.find_by_sql("SELECT distinct id from scan_procedures where protocol_id in ("+protocol_list+") ")

             @current_self_scan_procedure.each do |p2|
               scan_procedure_array << p2.id
               end
             self[:edit_low_scan_procedure_array] = scan_procedure_array
          end      

          if p.role == "View_High"
             # loop thru protocols and grant perms 
              protocol_array = []
             @current_self_protocol = self.protocol_roles.find_by_sql("SELECT distinct protocol_id from protocol_roles where role = '"+p.role+"' and user_id = "+(self.id).to_s)
             @current_self_protocol.each do |p2|
               protocol_array << p2.protocol_id
               end
             self[:view_high_protocol_array] = protocol_array
             protocol_list = protocol_array*","
             scan_procedure_array = []
             @current_self_scan_procedure = self.protocol_roles.find_by_sql("SELECT distinct id from scan_procedures where protocol_id in ("+protocol_list+") ")
             @current_self_scan_procedure.each do |p2|
               scan_procedure_array << p2.id
               end
             self[:view_high_scan_procedure_array] = scan_procedure_array
          end  

          if p.role == "View_Medium"
             # loop thru protocols and grant perms 
              protocol_array = []
             @current_self_protocol = self.protocol_roles.find_by_sql("SELECT distinct protocol_id from protocol_roles where role = '"+p.role+"' and user_id = "+(self.id).to_s)
             @current_self_protocol.each do |p2|
               protocol_array << p2.protocol_id
               end
             self[:view_medium_protocol_array] = protocol_array
             protocol_list = protocol_array*","
             scan_procedure_array = []
             @current_self_scan_procedure = self.protocol_roles.find_by_sql("SELECT distinct id from scan_procedures where protocol_id in ("+protocol_list+") ")
             @current_self_scan_procedure.each do |p2|
               scan_procedure_array << p2.id
               end
             self[:view_medium_scan_procedure_array] = scan_procedure_array
          end

          if p.role == "View_Low"
             # loop thru protocols and grant perms 
              protocol_array = []
             @current_self_protocol = self.protocol_roles.find_by_sql("SELECT distinct protocol_id from protocol_roles where role = '"+p.role+"' and user_id = "+(self.id).to_s)
             @current_self_protocol.each do |p2|
               protocol_array << p2.protocol_id
               end
             self[:view_low_protocol_array] = protocol_array
             protocol_list = protocol_array*","
             scan_procedure_array = []
             @current_self_scan_procedure = self.protocol_roles.find_by_sql("SELECT distinct id from scan_procedures where protocol_id in ("+protocol_list+") ")
             @current_self_scan_procedure.each do |p2|
               scan_procedure_array << p2.id
               end
             self[:view_low_scan_procedure_array] = scan_procedure_array
          end      

          if p.role == "Admin_High"
             # loop thru protocols and grant perms 
              protocol_array = []
             @current_self_protocol = self.protocol_roles.find_by_sql("SELECT distinct protocol_id from protocol_roles where role = '"+p.role+"' and user_id = "+(self.id).to_s)
             @current_self_protocol.each do |p2|
               protocol_array << p2.protocol_id
               end
             self[:admin_high_protocol_array] = protocol_array
             protocol_list = protocol_array*","
             scan_procedure_array = []
             @current_self_scan_procedure = self.protocol_roles.find_by_sql("SELECT distinct id from scan_procedures where protocol_id in ("+protocol_list+") ")
             @current_self_scan_procedure.each do |p2|
               scan_procedure_array << p2.id
               end
             self[:admin_high_scan_procedure_array] = scan_procedure_array
          end   

          if p.role == "Admin_Medium"
             # loop thru protocols and grant perms 
              protocol_array = []
             @current_self_protocol = self.protocol_roles.find_by_sql("SELECT distinct protocol_id from protocol_roles where role = '"+p.role+"' and user_id = "+(self.id).to_s)
             @current_self_protocol.each do |p2|
               protocol_array << p2.protocol_id
               end
             self[:admin_medium_protocol_array] = protocol_array
             protocol_list = protocol_array*","
             scan_procedure_array = []
             @current_self_scan_procedure = self.protocol_roles.find_by_sql("SELECT distinct id from scan_procedures where protocol_id in ("+protocol_list+") ")
             @current_self_scan_procedure.each do |p2|
               scan_procedure_array << p2.id
               end
             self[:admin_medium_scan_procedure_array] = scan_procedure_array
          end

          if p.role == "Admin_Low"
             # loop thru protocols and grant perms 
              protocol_array = []
             @current_self_protocol = self.protocol_roles.find_by_sql("SELECT distinct protocol_id from protocol_roles where role = '"+p.role+"' and user_id = "+(self.id).to_s)
             @current_self_protocol.each do |p2|
               protocol_array << p2.protocol_id
               end
             self[:admin_low_protocol_array] = protocol_array
             protocol_list = protocol_array*","
             scan_procedure_array = []
             @current_self_scan_procedure = self.protocol_roles.find_by_sql("SELECT distinct id from scan_procedures where protocol_id in ("+protocol_list+") ")
             @current_self_scan_procedure.each do |p2|
               scan_procedure_array << p2.id
               end
             self[:admin_low_scan_procedure_array] = scan_procedure_array     
          end      
      end   
  
       # get list of all protocol and scan_procedure
         protocol_array =[]
       @current_self_protocol = self.protocol_roles.find_by_sql("SELECT distinct id from protocols")
       @current_self_protocol.each do |p2|
         protocol_array << p2.id
         end
         protocol_list = protocol_array*","
         scan_procedure_array = []
         @current_self_scan_procedure = self.protocol_roles.find_by_sql("SELECT distinct id from scan_procedures where protocol_id in ("+protocol_list+") ")
         @current_self_scan_procedure.each do |p2|
           scan_procedure_array << p2.id
           end    

       if self.role == "Admin_High"
         self[:admin_high_scan_procedure_array] = scan_procedure_array
         self[:admin_high_protocol_array] = protocol_array
       elsif self.role  == "Admin_Medium"
         self[:admin_medium_scan_procedure_array] = scan_procedure_array
         self[:admin_medium_protocol_array] = protocol_array  
       elsif self.role  == "Admin_Low"
         self[:admin_low_scan_procedure_array] = scan_procedure_array
         self[:admin_low_protocol_array] = protocol_array
       elsif self.role  == "Edit_High"
         self[edit_high_scan_procedure_array] = scan_procedure_array
         self[:edit_high_protocol_array] = protocol_array

       elsif self.role  == "Edit_Medium"
         self[:edit_medium_scan_procedure_array] = scan_procedure_array
         self[:edit_medium_protocol_array] = protocol_array  
       elsif self.role  == "Edit_Low"
         self[:edit_low_scan_procedure_array] = scan_procedure_array
         self[:edit_low_protocol_array] = protocol_array
       elsif self.role  == "View_High"
         self[:view_high_scan_procedure_array] = scan_procedure_array
         self[:view_high_protocol_array] = protocol_array    
       elsif self.role  == "View_Medium"
         self[:view_medium_scan_procedure_array] = scan_procedure_array
         self[:view_medium_protocol_array] = protocol_array
       elsif self.role == "View_Low"
         self[:view_low_scan_procedure_array] = scan_procedure_array
         self[:view_low_protocol_array] = protocol_array
       end

       # populate sum of arrays --- admin-> edit
             # admin-> edit -> view 
             # driver is edit_low_,  view_low
           # merging nulls arrays 
           # poplate first self array with -1, pick up new procedures as go along?

       self[:edit_low_scan_procedure_array] = self[:edit_low_scan_procedure_array] | self[:admin_low_scan_procedure_array] | self[:admin_high_scan_procedure_array]
       self[:view_low_scan_procedure_array] = self[:edit_low_scan_procedure_array] | self[:view_low_scan_procedure_array]

       # also protocol
       self[:edit_low_protocol_array] = self[:edit_low_protocol_array] | self[:admin_low_protocol_array] | self[:admin_high_protocol_array]
       self[:view_low_protocol_array] = self[:edit_low_protocol_array] | self[:view_low_protocol_array] 

      #  self[:edit_low_scan_procedure_array] = [-1]
      #  self[:edit_low_protocol_array] = [-1]
     #  self[:view_low_scan_procedure_array] =[-1,-2,-3]

     if(field == 'view_low_scan_procedure_array')
       return self[:view_low_scan_procedure_array].join(' ')
      elsif(field == 'edit_low_scan_procedure_array')
        return self[:edit_low_scan_procedure_array].join(' ')
      elsif(field == 'admin_low_scan_procedure_array')
        return self[:admin_low_scan_procedure_array].join(' ')
      elsif(field == 'view_medium_scan_procedure_array')
        return self[:view_medium_scan_procedure_array].join(' ')
       elsif(field == 'edit_medium_scan_procedure_array')
         return self[:edit_low_scan_procedure_array].join(' ')
       elsif(field == 'admin_medium_scan_procedure_array')
         return self[:admin_medium_scan_procedure_array].join(' ')        
       elsif(field == 'view_high_scan_procedure_array')
         return self[:view_high_scan_procedure_array].join(' ')
        elsif(field == 'edit_high_scan_procedure_array')
          return self[:edit_high_scan_procedure_array].join(' ')
        elsif(field == 'admin_high_scan_procedure_array')
          return self[:admin_high_scan_procedure_array].join(' ')
      elsif(field == 'view_low_protocol_array')
        return self[:view_low_protocol_array].join(' ')
      elsif(field == 'edit_low_protocol_array')
        return self[:edit_low_protocol_array].join(' ')
      elsif(field == 'admin_low_protocol_array')
        return self[:admin_low_protocol_array].join(' ')
      elsif(field == 'view_medium_protocol_array')
        return self[:view_medium_protocol_array].join(' ')
      elsif(field == 'edit_medium_protocol_array')
        return self[:edit_medium_protocol_array].join(' ')
      elsif(field == 'admin_medium_protocol_array')
        return self[:admin_medium_protocol_array].join(' ')        
      elsif(field == 'view_high_protocol_array')
        return self[:view_high_protocol_array].join(' ')
      elsif(field == 'edit_high_protocol_array')
        return self[:edit_high_protocol_array].join(' ')
      elsif(field == 'admin_high_protocol_array')
        return self[:admin_high_protocol_array].join(' ')
      else
        var = [-1]
        return var.join(' ')
      end
    end

=begin
  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  def self.authenticate(login, password)
    u = find_by_login(login) # need to get the salt
    u && u.authenticated?(password) ? u : nil
  end

  # Encrypts some data with the salt.
  def self.encrypt(password, salt)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end

  # Encrypts the password with the user salt
  def encrypt(password)
    self.class.encrypt(password, salt)
  end

  def authenticated?(password)
    crypted_password == encrypt(password)
  end

  def remember_token?
    remember_token_expires_at && Time.now.utc < remember_token_expires_at 
  end

  # These create and unset the fields required for remembering users between browser closes
  def remember_me
    remember_me_for 2.weeks
  end

  def remember_me_for(time)
    remember_me_until time.from_now.utc
  end

  def remember_me_until(time)
    self.remember_token_expires_at = time
    self.remember_token            = encrypt("#{email}--#{remember_token_expires_at}")
    save(false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save(false)
  end

  # Returns true if the user has just been activated.
  def recently_activated?
    @activated
  end
=end  
  protected
    # before filter 
    def encrypt_password
      return if password.blank?
      self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--") if new_record?
      self.crypted_password = encrypt(password)
    end
      
    def password_required?
      crypted_password.blank? || !password.blank?
    end
  
    
end
