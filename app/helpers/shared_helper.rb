module SharedHelper
  
  def get_base_path()  # this is a duplicate of vgroup model function --- need a common location
    # should this be in shared_helper?
  	base_path =""
  	base_path ="/mounts/data"	
  	return base_path
  end
  
  private  
  # coupling functions at top of shared model
    def adrc_sftp_user
      'wisconsin'
    end  

    def adrc_sftp_host
         "128.208.132.61"
    end

    def adrc_sftp_pwd
      "wis567"
    end
    
    def dom_sftp_host
         "sftp.medicine.wisc.edu"
    end
    
    def panda_admin_sftp_user
      'panda_admin'
    end
    
    def panda_admin_sftp_pwd
      "2Wrong!79"
    end
    
    def panda_user_sftp_user
      'panda_user'
    end
    
    def panda_user_sftp_pwd
      "Rc529#jLp"
    end
    
    def antuano_target
      "Team/download_antuono"
    end
    
    def selley_target
      "Team/download_selley"
    end
end