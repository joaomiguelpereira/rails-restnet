class UsersController < WebappController
  
  before_filter :requires_authentication, :except=>[:new,:create,:reset_password, :recover_password, :activate]
  
  #List users
  # GET /users
  # GET /users.xml
  def index
    @users = User.all
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @users }
    end
  end
  
  # GET /users/1
  # GET /users/1.xml
  def show
    @user = User.find(params[:id])
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @user }
    end
  end
  
  # GET /users/new
  # GET /users/new.xml
  # Only works if there is no user logged in
  def new
    raise Webapp::UserSessionExistsError if session[:user_session]
    @user = User.new
    if facebook_user
      @user.first_name = facebook_user.first_name
      @user.last_name = facebook_user.last_name
    end
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @user }
    end
    
  rescue Webapp::UserSessionExistsError
    flash_error(:user_session_exists)
    redirect_to root_url
  end
  
  
  # POST /users
  # POST /users.xml
  def create
    #Create user instance
    @user = User.new(params[:user])
    @user.fb_uid = facebook_user.uid if facebook_user  
    if @user.save
      
      #flash[:notice] = sprintf(t(:user_created_confirmation_sent), @user.name,@user.email) unless facebook_user
      flash_notice(:user_created_confirmation_sent, @user.full_name,@user.email) unless facebook_user
      
      create_session(@user) if facebook_user
      redirect_to_last_page
    else
      render :action => "new"
    end
  end
  
  #Render the form where user will introduce email so we can send a reset password link if the request is
  # a get.Send a mail to the user if the email is found during a post
  def recover_password
    raise Webapp::UserSessionExistsError if user_session
    if request.get?
      @handle_or_user_name = ""  
      
    elsif request.post?
      @handle_or_user_name = params[:handle_or_email]
      raise Webapp::BadParametersError if @handle_or_user_name.nil? || @handle_or_user_name.empty?
      user = User.find_by_handle_or_email(@handle_or_user_name)
      #Should create a PasswordRecovery
      password_recovery = PasswordRecovery.create_password_recovery(user.id)
      #Should send an email
      UserMailer.deliver_recover_password_instructions(user)
      #TODO: Check why the message does not apears correctly in Web GUI
      #message = sprintf(t(:recover_password_instructions_sent),
      flash_notice(:recover_password_instructions_sent,user.email)
      redirect_to root_url
      #should flash a message and redirect to root_url
      
    else
      raise Webapp::BadRequestError
    end
    
  rescue Webapp::BadRequestError
    logger.error("Invalid Request type. Client IP: "+request.remote_ip)
    flash_error(:invalid_request)
    redirect_to root_url
    
  rescue Webapp::UserSessionExistsError
    logger.error "Attempt to recover a password within a user session. Client IP: "+request.remote_ip
    flash_error(:user_session_exists)
    redirect_to root_url
  rescue Webapp::BadParametersError, ActiveRecord::RecordNotFound
    logger.error("Attempt to recover a password but email or user name was not provided or not found Email or Name was #{@email_or_user_name}. Client IP:"+request.remote_ip)
    flash_error(:invalid_login_name_or_email)
    redirect_to recover_password_url
  end
  
  #Reset the password for a user
  def reset_password
    if request.get?
      @key = params[:key]
      @user_id = params[:id]
      @password = ""
      @password_confirmation =""
      raise Webapp::BadParametersError if @key.nil? || @user_id.nil?
      user = User.find(@user_id)
      #check if user has previouly requested a chenge to the password
      password_recovery = PasswordRecovery.find_by_user_id(@user_id)
      raise Webapp::NoSuchPasswordRecovery if password_recovery.nil?
      raise Webapp::BadParametersError if @key != password_recovery.key
    elsif request.put?
      @key = params[:key]
      
      @user_id = params[:id]
      @password = params[:password]
      @password_confirmation =params[:password_confirmation]
      raise Webapp::BadParametersError if (@key.nil? || @key.empty? || @user_id.nil? || @user_id.empty? ||
                                           @password.nil? || @password.empty? || @password_confirmation.nil? || @password_confirmation.empty?)
      
      #TODO: link this validation to model validation
      raise Webapp::InvalidPasswordError if @password.size < 5 || @password.size > 150
      raise Webapp::NoPasswordMatchError if @password != @password_confirmation
      
      user = User.find(@user_id)
      password_recovery = PasswordRecovery.find_by_user_id(user.id)
      raise Webapp::NoSuchPasswordRecovery if password_recovery.nil?
      
      #now we can change the password and remove the PasswordRecovery
      #Do this inside a small transaction
      user.transaction do
        user.password=@password
        PasswordRecovery.destroy(password_recovery.id)
        user.save!
        flash_notice(:password_changed_successfully)
        redirect_to new_session_url
      end
    else
      raise Webapp::BadRequestError
    end
    
  rescue Webapp::InvalidPasswordError
    logger.error("Invalid password format. Client IP: "+request.remote_ip)
    flash_error(:invalid_password)
    render :action=>:reset_password
  rescue Webapp::NoPasswordMatchError
    logger.error("Password don't match. Client IP: "+request.remote_ip)
    flash_error(:password_dont_match)
    render :action=>:reset_password
    #Error Handling
  rescue Webapp::BadRequestError
    logger.error("Invalid Request type. Client IP: "+request.remote_ip)
    flash_error(:invalid_request)
    redirect_to root_url
  rescue Webapp::NoSuchPasswordRecovery 
    logger.error("Trying to reset password for a user that haven't request a pass change. Client IP: "+request.remote_ip)
    flash_error(:reset_password_invalid_key)
    redirect_to root_url
    
  rescue Webapp::BadParametersError
    logger.error("Invalid data provided when reseting password. Client IP: "+request.remote_ip)
    flash_error(:reset_password_invalid_key)
    redirect_to root_url
  rescue ActiveRecord::RecordNotFound
    logger.error("User not found when reseting password. Client IP: "+request.remote_ip)
    flash_error(:user_not_found)
    redirect_to root_url
  end
  #
  #
  #
  def change_password
    if request.get?
      @current_password=""
      @password=""
      @password_confirmation=""
    elsif request.put?
      @current_password = params[:current_password]
      @password = params[:password]
      @password_confirmation = params[:password_confirmation]
      user = User.find(params[:id])
      
      raise Webapp::WrongPasswordError unless User.authenticate_with_handle_or_email(user.handle, @current_password)
      raise Webapp::NoPasswordMatchError if @password != @password_confirmation
      raise Webapp::InvalidPasswordError if @password.size < 5 || @password.size > 150
      user.password=@password
      user.save
      flash_notice(:password_changed_successfully)
      redirect_to(user)
      
    else
      raise Webapp::BadRequestError
    end
  rescue Webapp::FBUserNotAuthenticableError
    logger.error("Cannot change password for facebooks user. Request IP: "+request.remote_ip)
    flash_error(:password_not_changeable_for_facebook_user)
    redirect_to(user)
  rescue Webapp::WrongPasswordError
    logger.error("Wrong password while changing password. Request IP: "+request.remote_ip)
    flash_error(:wrong_password)
    render :action=>:change_password
  rescue Webapp::NoPasswordMatchError
    logger.error("Password don't match while changing password. Request IP: "+request.remote_ip)
    flash_error(:password_dont_match)
    render :action=>:change_password
  rescue Webapp::InvalidPasswordError
    logger.error("Password has invalid format")
    flash_error(:invalid_password)
    render :action=>:change_password
    
  rescue Webapp::BadRequestError
    logger.error("Only put or get for change password")
    flash_error(:invalid_request)
    redirect_to_last_page
    
    
  end
  
  #/user/user_id/activate/activation_key
  def activate
    #Get from the params hash the activation key
    activation_key = params[:activation_key]
    #Get from the params Hash the user id
    user_id =params[:id]
    @user = User.find(user_id)
    #check if the key is valid
    
    #raise and exception if the user is already active
    raise SecurityError if @user.active?
    
    #raise an exception if the activation keys do not match
    raise ArgumentError if activation_key != @user.activation_key 
    
    @user.active=1
    @user.save
    flash[:notice] = I18n.t(:user_activated_success_message)
    #After activation, ask user to create a new session with the web app
    redirect_to new_session_url
    
    # rescue ActiveRecord::RecordNotFound
    #   logger.info("Record not found")
    #    raise
  rescue ArgumentError #If keys do not match
    #send user to home
    logger.error("Attempt to activate user #{@user.full_name} with wrong activation key. Client IP: "+request.remote_ip)
    flash[:error] = I18n.t(:invalid_activation_key_error)
    redirect_to root_url
  rescue SecurityError
    #send user to index
    logger.error("Attempt to activate user #{@user.full_name} that is already activated. Client IP: "+request.remote_ip)
    flash[:error] = I18n.t(:user_already_active_error)
    redirect_to new_session_url
  rescue ActiveRecord::RecordNotFound
    logger.error("Attempt to activate not existent user. Client IP: "+request.remote_ip)
    flash[:error] = I18n.t(:user_not_found)
    redirect_to root_url
  end
  # GET /users/1/edit
  def edit
    #@user = get_user_for_update(params[:id])
    @user = User.find(params[:id])
    
  end
  # PUT /users/1
  # PUT /users/1.xml
  def update
    #Can update first name, last name, email and handle
    #@user = get_user_for_update(params[:id])
    @user = User.find(params[:id])
    respond_to do |format|
      if @user.update_attributes(params[:user])
        user_session.name = @user.full_name
        flash_notice(:user_data_updated)
        format.html { redirect_to(@user) }
        format.xml  { head :ok }
      else
        flash_error(:user_data_not_updated)
        format.html { render :action => "edit" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  rescue
    logger.error("error updating user")
  end
  # DELETE /users/1
  # DELETE /users/1.xml
  def destroy
    #raise Webapp::NotAllowedError unless has_session?
    #user = User.find(user_session.user_id)
    #@user = get_user_for_update(params[:id])
    @user = User.find(params[:id])
    #raise Webapp::NotAllowedError unless user.admin || user.id == @user.id
    @user.destroy
    
    #loging out
    clear_user_session(params[:id]) if user_session.user_id.to_s == params[:id].to_s    
    flash_notice(:user_removed)
    respond_to do |format|
      format.html { redirect_to(users_url) }
      format.xml  { head :ok }
    end
    
  end
  
  private 
  def requires_authentication
    raise Webapp::NotAllowedError unless has_session?
    authenticated_user = User.find(user_session.user_id)
    user = User.find(params[:id])
    raise Webapp::NotAllowedError unless authenticated_user.admin || authenticated_user.id == user.id
  rescue Webapp::NotAllowedError
    logger.error("An attempt to remove/edit a user with no valid authentication. IP Address "+request.remote_ip)
    flash_error(:not_allowed)
    redirect_to_last_page
  rescue ActiveRecord::RecordNotFound
    logger.error("Strange... The user in the session does not exists.Remote IP:"+request.remote_ip)
    flash_error(:not_allowed)
    redirect_to_last_page
  end
  
  
  # def get_user_for_update(user_id)
  #   raise Webapp::NotAllowedError unless has_session?
  #   user = User.find(user_session.user_id)
  #   @user = User.find(user_id)
  #   raise Webapp::NotAllowedError unless user.admin || user.id == @user.id
  #   @user
  # end
  
end
