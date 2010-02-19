class SessionsController < WebappController
  
  def new
    #Try to auto login the user
    #do_auto_login if session[:user_session].nil? && cookies[WebappConstants::AUTO_LOGIN_COOKIE_NAME]
    #I need to ask for email/username, password and the keeplogged in
    #Initialize the instance vars   
    @handle_or_email = ""
    @password =""
    @keep_me_logged = "1"
    
  end
  #  def create_with_facebook
  #    
  #    raise Webapp::NoFBSessionError unless facebook_user
  #    user = User.find_by_fb_uid(facebook_user.uid)
  #    create_session(user)
  #    redirect_to_last_page 
  #  rescue Webapp::NoFBSessionError
  #    logger.error("An attempt to create a session for facebook but without a facebook user")
  #    flash_error(:could_not_connect_to_fb)
  #    redirect_to_last_page
  #    
  #  rescue ActiveRecord::RecordNotFound
  #    #log and redirect
  #    logger.warn("An attempt to make a login with invalid name or email #{@name_or_email}")
  #    #add a :error message
  #    flash_error(:invalid_login_name_or_email)
  #    @password = ""
  #    redirect_to_last_page
  #  end
  
  def create
    #Resets the session by clearing out all the objects stored within and initializing a new session object.
    reset_session
    @handle_or_email = params[:handle_or_email]
    @password = params[:password]
    @keep_me_logged = params[:keep_me_logged]
    @keep_me_logged = "0" if params[:keep_me_logged].nil?  
    #verify is password is empty
    #raise Webapp::BlankPasswordError if @password.nil? or @password.empty? 
    #The authenticate with name or email will raise exceptions if wrong password or name/email is provided
    user = User.authenticate_with_handle_or_email(@handle_or_email, @password)
    create_persistent_session(user.id) if @keep_me_logged=="1"  
    create_session(user,facebook_user)
    redirect_to_last_page 
    #Create new UserSession from the user
    #user_session = UserSession.new(user)
    
    #session[:user_session] = user_session
    #flash_notice(:login_successfull)
    #Create a persistent session if user want to be auto logged
    
    #cookies[Webapp::Constants.auto_login_cookie_name] = create_auto_login_cookie_value(PersistentSession.create_session(user.id)) if @keep_me_logged == "1"
    #redirect_to root_url 
  rescue ActiveRecord::RecordNotFound
    #log and redirect
    logger.warn("An attempt to make a login with invalid name or email #{@handle_or_email}")
    #add a :error message
    flash_error(:invalid_login_name_or_email)
    @password = ""
    redirect_to new_session_url
    
  rescue Webapp::WrongPasswordError
    #log and redirect
    logger.warn("An attempt to make a login with wrong password for name or email #{@handle_or_email}")
    #add a :error message
    flash_error(:wrong_password)
    #redirect_to new_session_url
    render :action=>:new, :status=>:unauthorized
  rescue Webapp::UserNotActiveError
    #log and redirect
    logger.warn("An attempt to make a login with not active user #{@handle_or_email}")
    #add a :error message
    #add a :error message
    @password = ""
    flash_error(:user_not_activated_yet)
    redirect_to root_url
  rescue Webapp::FBUserNotAuthenticableError
    logger.warn("An attempt to make a login a facebook user #{@handle_or_email}")
    flash_error(:fb_user_not_authenticable_message,@handle_or_email)
    redirect_to new_session_url
  end
  
  ##Destroy a user session if it exists, raise exception otherwise
  def destroy
    #allways ensure that the facebook session is destroyed
    #ssion[:facebook_session] = nil
    logger.info("Destroying session for user : #{session[:user_session]}")
    user_id = session[:user_session].user_id if session[:user_session]
    clear_user_session(user_id)
    #session[:user_session] = nil
    #destroy persistent session
    #remove_persistent_session(user_id) if user_id
    #reset_session
    flash_notice(:session_destroyed)
    redirect_to root_url
    
  end
  
  
  
  
  
end