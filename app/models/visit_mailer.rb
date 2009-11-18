class VisitMailer < ActionMailer::Base
  
  def visit_confirmation(visit, email_params = { :send_to => "erik.kastman@gmail.com"}, sent_at = Time.now)
    recipients  email_params[:send_to]
    from        "noreply_johnson_lab@medicine.wisc.edu"
    reply_to    "Erik Kastman <erik.kastman@gmail.com>"
    subject     "[Data Panda] New Visit: #{visit.rmr}"
    sent_on sent_at

    # allows access to @message and @sender_name
    # in the view
    body({
      :user => visit.created_by.login, 
      :message => visit.id, 
      :visit_date => visit.date, 
      :visit_path => visit.path,
      :created_at => DateTime.now.to_formatted_s(:datetime_daymonthweek), 
      #:enrollment_enum => visit.enrollment.enum,
      :rmr => visit.rmr,
      :image_datasets => visit.image_datasets
    })
  end
  
end
