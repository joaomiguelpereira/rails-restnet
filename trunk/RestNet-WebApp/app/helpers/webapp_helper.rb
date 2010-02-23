module WebappHelper
  
  
  def page_title
    "some page title"
  end
  def keywords
    "teste keywords"
  end
  
  def template_css
    WEBAPP_CONFIG['template_css']
  end
  def template_name
    WEBAPP_CONFIG['template']
  end
  def statics_url
    #Assumes the same host and same protocol by default
    #Check webapp_config.yml for the variable statics_url  
    WEBAPP_CONFIG['statics_url'] || request.protocol+request.host_with_port
    
  end
  
  
  def images_url
    #check webapp_config.yml for images_dir
    statics_url+WEBAPP_CONFIG['images_dir']     
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
