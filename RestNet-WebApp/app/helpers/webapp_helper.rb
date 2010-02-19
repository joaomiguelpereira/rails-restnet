module WebappHelper
  
  #
  # Generate a list of keywords to insert into the template. Each controller can override it
  def keywords
    "Add Logic here to generate the keywords for all app. Override in each controller"
  end
  
  def template_name
    "refresh"
  end
  def statics_url
    #Assumes the same host and same protocol
    request.protocol+request.host_with_port
  end
  def images_url
    statics_url+"/templates/#{template_name}/images/"  
  end
  def has_session?
    return true if session[:user_session]
    false
  end
  
  #convenience method to get the user_session or nil if none
  def user_session
    session[:user_session]
  end
  def facebook_session
    session[:facebook_session]
  end
  
  def facebook_user
   (session[:facebook_session] && session[:facebook_session].session_key) ? session[:facebook_session].user : nil
  end
end
