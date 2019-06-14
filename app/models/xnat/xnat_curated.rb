class Xnat::XnatCurated < ActiveRecord::Base

      self.abstract_class = true
     #This is a base class for our uploaders

      #create
     #check
     #publish
     #unpublish

 
      protected
     def r_call(cmd)
         begin
         	stdin, stdout, stderr = Open3.popen3(cmd)
             while !stdout.eof?
             	puts stdout.read 1024    
             end
             stdin.close
             stdout.close
             stderr.close
         rescue => msg
         end
     end

  end