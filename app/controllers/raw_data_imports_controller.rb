require 'metamri'
class RawDataImportsController < ApplicationController
  
  def new
    @recent_visits = Visit.where(:created_at.lt => 1.month.ago).all
    # vipr files need to be bzip2 or they don't get imported into panda
    respond_to do |format|
      format.html # new.html.erb
    end
  end
  
  def create
    @visit_directory_to_scan = params[:raw_data_import][:directory].chomp(' ')
    if validates_truthiness_of_directory(@visit_directory_to_scan)
      v = VisitRawDataDirectory.new(@visit_directory_to_scan, params[:raw_data_import][:scan_procedure])
      logger.info "Current User: #{Etc.getlogin}"
      logger.info  "+++ Importing #{v.visit_directory} as part of #{v.scan_procedure_name} +++"
      begin
        v.scan
      rescue Exception => e
        v = nil
        flash[:error] = "Awfully sorry, this raw data directory could not be scanned. #{e}"
      end
      unless v.nil?
        puts "GGGGGGGGGG before Visit.create_or_update_from_metamri"
        @visit = Visit.create_or_update_from_metamri(v, created_by = current_user)
        unless @visit.new_record?
          flash[:notice] = "Sucessfully imported raw data directory."
          begin
            PandaMailer.visit_confirmation(@visit, {:send_to => "noreply_johnson_lab@medicine.wisc.edu"}).deliver
            flash[:notice] = flash[:notice].to_s + "; Email was succesfully sent."
          rescue Errno::ECONNREFUSED, LoadError, OpenSSL::SSL::SSLError => load_error
            logger.info load_error
            flash[:error] = "Sorry, your email was not delivered: " + load_error.to_s
          rescue Timeout::Error => timeout_error
            logger.info timeout_error
            flash[:error] = "Sorry, mail took too long to be delivered: " + timeout_error.to_s
          end
        else
          logger.info @visit.errors
          flash[:error] = "Awfully sorry, this raw data directory could not be saved to the database. #{@visit.errors}"
        end
      end
      redirect_to root_url
    else
      flash[:error] = "Invalid raw data directory #{@visit_directory_to_scan}, please check your path and try again."
      redirect_to new_raw_data_import_path
    end
  end
  
  def validates_truthiness_of_directory(dir)
  ####  File.directory?(dir) # =~ /^\/Data\/vtrak1\/raw\//
        File.directory?(dir) # =~ /^\/Volumes\/team*\/raw\//
  end

end