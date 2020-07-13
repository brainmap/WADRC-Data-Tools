module SharedHelper

  def get_base_path()  # this is a duplicate of vgroup model function --- need a common location
    # should this be in shared_helper?
  	base_path =""
  	base_path ="/mounts/data"	
  	return base_path
  end
  
  private  
    def adrc_sftp_user
      'wisconsin'
    end  

    def adrc_sftp_host
         "128.208.132.61"
    end

    def adrc_sftp_pwd
      "wis567"
    end

    def booked_disconnect_user
      'goveas'
    end

    def booked_disconnect_pwd
       'Ued294Max!'
    end

    def booked_address_base
         "booked.medicine.wisc.edu"
    end

    def booked_address_page
         "/booked/Web/dashboard.php?"
    end

    def xnat_user
        "panda_uploader"
    end

    def xnat_pwd
        "5es9~FWPyqu"
    end

    def xnat_site
         'xnat.medicine.wisc.edu'
    end 

    

end
