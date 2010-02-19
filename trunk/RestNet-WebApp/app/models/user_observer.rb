class UserObserver < ActiveRecord::Observer
  def after_create(user)
    UserMailer.deliver_signup_confirmation(user) unless user.facebook_user?
  end
end