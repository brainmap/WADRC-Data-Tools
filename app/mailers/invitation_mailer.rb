class InvitationMailer < ActionMailer::Base
  default :from => 'noreply_johnson_lab@medicine.wisc.edu'

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.invitation_mailer.invite.subject
  #
  def invite(invitation)
    @invite = invitation
    mail :to => invitation.email,
         :subject => "Welcome to the Panda"
  end
  
  def notify_admin(invitation)
    @invite = invitation
    mail :to => 'noreply_johnson_lab@medicine.wisc.edu',
         :subject => "Panda invite requested"
  end
end
