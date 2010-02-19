class UserMailer < ActionMailer::Base
  
  def signup_confirmation(user)
    setup_email(user.email)
    @subject = I18n.t(:activate_account_email_subject)
    @body = {:user=>user, :url => "#{WEBAPP_CONFIG["webapp_site"]}/user/activate/#{user.id}/#{user.activation_key}"}
  end
  
  def recover_password_instructions(user)
    setup_email(user.email)
    @subject = I18n.t(:recover_password_email_subject)
    password_recovery = PasswordRecovery.find_by_user_id(user.id)
    url = "#{WEBAPP_CONFIG["webapp_site"]}/user/reset_password/#{user.id}/#{password_recovery.key}"
    @body = {:user=>user, :url => url}
  end
  
  protected
  def setup_email(email)
    @recipients = "#{email}"
    @from = "#{WEBAPP_CONFIG["emails"]["info_from"]}"
    @sent_on = Time.now
    @content_type = "text/html"
    
  end
end
