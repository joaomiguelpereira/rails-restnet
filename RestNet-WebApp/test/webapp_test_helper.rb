
class WebappFunctionalTestCase < ActionController::TestCase
  
  def assert_error_flashed(message,*strs)
    #aasert that in the flash exists the :error symbol with the :message
    assert_equal sprintf(I18n.t(message),*strs), flash[:error]
  end
  
  def assert_notice_flashed(message, *strs)
    assert_equal sprintf(I18n.t(message),*strs), flash[:notice]
  end
  
  def assert_no_user_session
    assert_nil session[:user_session]
  end
  def assert_user_session
    assert_not_nil session[:user_session]
  end
end

class WebappUnitTestCase < ActiveSupport::TestCase
  
end

