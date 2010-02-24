module UsersHelper
  def profile_picture_url
    if @facebook_user
      return @facebook_user.pic_small 
    else
      return image_path("profile_picture.gif")
    end
  end
end
