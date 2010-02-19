require 'webapp_exceptions'
class WebappController < ApplicationController
  helper :all # include all helpers, all the time
  include ApplicationHelper
  include WebappHelper
  
  before_filter :detect_auto_login_cookie
  #Define the base layout. For not hard coded
  layout :determine_layout
  
  protected
  #determine the layout to use
  def determine_layout
    #"earthlingtwo/earthlingtwo"
    "#{template_name}/#{template_name}"
  end
  
  #Convenience method to add an error to the flash
  def flash_error(message_key,*strs)
    flash[:error] = sprintf(I18n.t(message_key),*strs)
  end
  
  #Convenience method to add and note to flash
  def flash_notice(message_key, *strs)
    flash[:notice] = sprintf(I18n.t(message_key),*strs)
  end
  
  def redirect_with_error(message_key, *strs)
    new_url = session[:return_to] || root_url
    session[:return_to] = nil
    flash_error(message_key, *strs)
    redirect_to new_url
  end
  
  def redirect_to_last_page
    new_url = session[:return_to] || root_url
    session[:return_to] = nil
    redirect_to new_url
  end
  
  #If a User session does not exists but a cookie to login exists, then try to do an auto login
  def detect_auto_login_cookie    
    logger.info("-----------------detecting loginf cookie")
    if session[:user_session].nil? && cookies[WebappConstants::AUTO_LOGIN_COOKIE_NAME]
      session[:return_to] = request.request_uri
      logger.info("doing auto login")
      do_auto_login
      #redirect_to :controller=>:session, :action=>do_auto_login
    end
    
  end
  
  def create_session(user, facebook_user=nil)
    user_session = UserSession.new(user, facebook_user)
    session[:user_session] = user_session
    flash_notice(:login_successfull)
    
  end
  
  def do_auto_login
    user_id = get_user_id_from_auto_login_cookie_value(cookies[WebappConstants::AUTO_LOGIN_COOKIE_NAME])
    key = get_key_from_auto_login_cookie_value(cookies[WebappConstants::AUTO_LOGIN_COOKIE_NAME])
    puts("-----------------------user_id:"+user_id.to_s)
    puts(".......................key:"+key)
    
    user = User.find(user_id)
    if  user 
      puts("found user..."+user.handle)
      persistent_session = PersistentSession.find_by_user_id(user_id)
      if persistent_session 
        puts("found persistent session")
        puts("persisted key:"+persistent_session.key)
        if persistent_session.key == key
          puts("Keys are equal")
          #login the user
          user_session = UserSession.new(user)    
          session[:user_session] = user_session
          #create new persisten session
          create_persistent_session(user.id)
          #PersistentSession.create_session(user_id) 
          #Add cookie
          #cookies[WebappConstants::AUTO_LOGIN_COOKIE_NAME] = 
          redirect_to_last_page
          #redirect_to session[:return_to] || root_url
          
          #session[:return_to] = nil
        else
          remove_persistent_session(user_id)
          redirect_to root_url
        end
      else
        redirect_to root_url
      end    
    end
  end 
  
  def remove_persistent_session(user_id)
    cookies.delete WebappConstants::AUTO_LOGIN_COOKIE_NAME
    PersistentSession.clear_session(user_id)
  end
  
  def clear_user_session(user_id)
    session[:user_session] = nil
    remove_persistent_session(user_id)
    session[:facebook_session] = nil
    reset_session
  end
  
  def create_persistent_session(user_id)
    cookies[WebappConstants::AUTO_LOGIN_COOKIE_NAME]= {:value=>create_auto_login_cookie_value(PersistentSession.create_session(user_id)), 
      :expires=>WebappConstants::MAX_AUTO_LOGIN_COOKIE_AGE.days.from_now}
  end
  
  def create_auto_login_cookie_value(persistent_session)
    "#{persistent_session.user_id}:#{persistent_session.key}"
  end
  def get_user_id_from_auto_login_cookie_value(cookie_value)
    value = /\A\d+/i.match(cookie_value).to_s.to_i
  end
  
  def get_key_from_auto_login_cookie_value(cookie_value) 
    value = /[^\d:][\S]+/i.match(cookie_value).to_s
  end
  
  
end