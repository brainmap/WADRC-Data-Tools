class PandaMailer < ActionMailer::Base
  default :from => "noreply_johnson_lab@medicine.wisc.edu"
  
  def visit_confirmation(visit, email_params)
    raise(LoadError, "Unable to send to external email addresses without email credentials.") if !email_params[:send_to].ends_with?('@medicine.wisc.edu') unless self.class.smtp_credentialed?
    @visit = visit
    @username = visit.created_by.login if visit.created_by

    mail(
      :to => email_params[:send_to], 
      :subject => "[Data Panda] New Visit: #{visit.rmr}"
    )
  end
  
  def self.smtp_credentialed?
    !ActionMailer::Base.smtp_settings[:user_name].blank? && !ActionMailer::Base.smtp_settings[:password].blank?
  end
end
