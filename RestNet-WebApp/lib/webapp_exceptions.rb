module Webapp
  
  ##Exceptions for the web App.
  ## TODO: Check what is the best base Exception  
  class NotAllowedError < StandardError
    
  end
  
  class FBUserNotAuthenticableError < StandardError
    
  end
  class FBUserNotRegisteredError < StandardError
    
  end
  class NoFBSessionError < StandardError
    
  end
  class UserNotActiveError < StandardError
    
  end
  class InvalidPasswordError < StandardError
    
  end
  class NoPasswordMatchError < StandardError
    
  end
  class BadRequestError < StandardError
    
  end
  
  class NoSuchPasswordRecovery < StandardError
    
  end
  class BadParametersError < StandardError
    
  end
  class NotImplemented < StandardError
    
  end
  class WrongPasswordError < StandardError
    
  end
  class NoSuchSessionError < StandardError
    
  end
  class UserSessionExistsError < StandardError
    
  end
end

