class FbConnectController < WebappController
  
  def authenticate
    @facebook_session = Facebooker::Session.create(Facebooker.api_key, Facebooker.secret_key)
    logger.debug "facebook session in authenticate: #{facebook_session.inspect}"
    redirect_to @facebook_session.login_url
  end
  
  def facebook_session=(session) 
    @facebook_session =session
  end
  
  def connect
    begin
      secure_with_token!
      session[:facebook_session] = @facebook_session
      logger.debug "facebook session in connect: #{facebook_session.inspect}"
      raise Webapp::NoFBSessionError unless @facebook_session
      #Ok, there is a session
      if (facebook_user ) 
        user = User.find_by_fb_uid(facebook_user.uid)  
      end
      
      raise Webapp::FBUserNotRegisteredError unless user
      create_session(user, facebook_user)
      redirect_to_last_page
      
    end
  rescue Webapp::FBUserNotRegisteredError
    logger.warn("The user is connected but is not registered")
    #let's try to register
    redirect_to new_user_url
  rescue Facebooker::Session::MissingOrInvalidParameter
    return redirect_to(:action => 'authenticate')
  rescue Webapp::NoFBSessionError
    logger.warn("Called facebook connect without a session")
    redirect_with_error(:could_not_connect_to_fb)
  rescue
    logger.error("There was a fatal error while connecting user to facebook")
  end
  #if facebook_user
  # logger.debug("Looking if the user is already registered in the our service....")
  #if user = User.find_by_fb_uid(facebook_user.uid)
  #  login_user(user)
  #  return redirect_to('/')
  #end
  
  # not a linked user, try to match a user record by email_hash
  #if facebook_user.email_hashes.nil?
  #  logger.info("email_hashes is nil")
  #end
  #if facebook_user.email_hashes.empty?
  #  logger.info("email_hashes is empty")
  #end
  
  #facebook_user.email_hashes.each do |hash|
  # logger.debug(hash)
  #  if user = User.find_by_email_hash(hash)
  #    user.update_attribute(:fb_uid, facebook_user.uid)
  #    login_user(user)
  #    return redirect_to('/')
  #  end
  #end
  
  # joining facebook user, send to fill in username/email
  #return redirect_to(:controller => 'login', :action => 'register', :fb_user => 1)
  #end
  #redirect_to root_url
  # facebook quite often craps out and gives us no data
  #rescue Curl::Err::GotNothingError
  #  return redirect_to(:action => 'authenticate')
  
  # it seems sometimes facebook gives us a useless auth token, so retry
  
  
  #rescue Facebooker::Session::MissingOrInvalidParameter
  #  return redirect_to(:action => 'authenticate')
  #  render(:nothing => true)
  #end
  # callbacks, no session
  def post_authorize
    if linked_account_ids = params[:fb_sig_linked_account_ids].to_s.gsub(/\[|\]/,'').split(',')
      linked_account_ids.each do |user_id|
        if user = User.find_by_id(user_id)
          user.update_attribute(:fb_uid, params[:fb_sig_user])
        end
      end
    end
    
    render :nothing => true
  end
end