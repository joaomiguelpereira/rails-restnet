class User < ActiveRecord::Base
  before_create :before_create_user
  #accept_terms
  attr_accessible(:terms)
  validates_acceptance_of(:terms, :message=>:accept_terms,:on=>:create)
  #handle
  attr_accessible(:handle)
  validates_uniqueness_of(:handle, :case_sensitive=>false)
  validates_length_of(:handle,:minimum=>4, :on=>:update)
  validates_length_of(:handle,:maximum=>15, :on=>:update)
  validates_format_of(:handle, 
  :with=>/\A(?:[a-z\d](?:[a-z\d_]*[a-z\d])?)(?:[a-z\d](?:[a-z\d-]*[a-z\d])?)(?:\.[a-z\d](?:[a-z\d-]*[a-z\d])?)*\Z/i,
  :message=>:handle_invalid_format,:on=>:update)
  
  #first_name
  attr_accessible(:first_name)
  validates_presence_of(:first_name)
  validates_length_of(:first_name, :maximum => 15)
  
  #last_name
  attr_accessible(:last_name)
  validates_presence_of(:last_name)
  validates_length_of(:last_name, :maximum => 15)
  
  #Password
  attr_accessible :password_confirmation, :password
  validates_confirmation_of :password, :on=>:create, :unless=>:facebook_user?
  validates_length_of :password, :minimum=>5, :on=>:create, :unless=>:facebook_user?
  validates_length_of :password, :maximum=>150, :on=>:create, :unless=>:facebook_user?
  validate :password_not_blank, :on=>:create, :unless=>:facebook_user?
  
  
  #Email
  attr_accessible :email
  validates_presence_of :email
  validates_uniqueness_of :email, :case_sensitive=>false
  validates_confirmation_of :email, :unless=>:facebook_user?
  validates_format_of :email, 
  :with=>/^(([A-Za-z0-9]+_+)|([A-Za-z0-9]+\-+)|([A-Za-z0-9]+\.+)|([A-Za-z0-9]+\++))*[A-Za-z0-9]+@((\w+\-+)|(\w+\.))*\w{1,63}\.[a-zA-Z]{2,6}$/i, 
  :message=>:email_invalid
  
  
  ####################
  # Attributes
  ####################
  def full_name
    self.first_name+" "+self.last_name
  end
  #Password reader
  def password
    @password
  end
  
  #Password writer
  def password=(pwd)
    raise Webapp::FBUserNotAuthenticableError if facebook_user?
    @password = pwd
    return if pwd.blank?
    create_new_salt
    self.hashed_password = User.encrypt_password(self.password, self.salt)
  end
  
  
  #Authenticate a User using the name and password
  #def self.authenticate_with_name(name, password)
  #  #find the user
  #  user = self.find_by_name(name)
  #  authenticate(user,password) 
  #end
  
  #Authenticate a User using the email and password
  #Will raise ActiveRecord::RecordNotFound if the user could not be found
  #Will raise Webapp::WrongPasswordError if the password is wrong
  def self.authenticate_with_handle_or_email(handle_or_email, password)
    
    user = self.find_by_handle_or_email(handle_or_email)
    raise Webapp::FBUserNotAuthenticableError if user.facebook_user?
    authenticate(user,password)
  end
  
  #Override to_xml
  def to_xml(options={})
    default_only = [:id, :first_name, :last_name, :handle]
    options[:only] =(options[:only]||[]) + default_only
    super(options)
  end
  
  def self.find_by_handle_or_email(name_or_email)
    user = self.find_by_handle(name_or_email)
    user = self.find_by_email(name_or_email) unless user
    raise ActiveRecord::RecordNotFound unless !user.nil?
    user
  end
  
  
  def facebook_user?
    fb_uid && fb_uid != 0
    
  end
  private
  #Before a User is created, it set an activation key
  def before_create_user
    logger.debug("on before creare user")
    #Generate a unique key
    if facebook_user?
      self.active = 1  
    else
      activation_key_string = self.salt+self.email+self.hashed_password
      self.activation_key =Digest::SHA1.hexdigest(activation_key_string)
      self.active = 0
    end
    self.admin = 0 
    self.handle=generate_unique_handle
    
  end
  
  def generate_unique_handle
    length=15
    handle = StringUtils::generate_random_words(length)
    while User.find_by_handle(handle) do
      handle = StringUtils::generate_random_words(length)
    end
    handle
    
  end
  def self.authenticate(user, password)
    expected_password = encrypt_password(password, user.salt)
    raise Webapp::WrongPasswordError unless user.hashed_password == expected_password
    raise Webapp::UserNotActiveError if !user.active
    user
  end
  
  def password_not_blank
    errors.add(:password, :missing_password) if hashed_password.blank?
  end
  
  #Create a unique salt value, combine it with the plain-text password into a single string, and
  #then run an SHA1 digest on the result, returning a 40-character string of hex digits book - pag 161*/
  def self.encrypt_password(password, salt)
    string_to_hash = password+"wibble"+salt;
    Digest::SHA1.hexdigest(string_to_hash)
  end
  
  #  #We’ll create a salt string by concatenating a random number and the object
  #  #id of the user object. It doesn’t much matter what the salt is as long as it’s
  #  #unpredictable (using the time as a salt, for example, has lower entropy than
  #  #a random string). We store this new salt into the model object’s salt attribute.*/
  def create_new_salt
    logger.debug "Timestamp: "+Time.now.to_i.to_s
    self.salt = self.object_id.to_s + Time.now.to_i.to_s
  end
  
end
