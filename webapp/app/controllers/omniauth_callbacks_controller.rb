class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def tls
    auth_data = request.env['omniauth.auth']
    @user = User.first_or_create(email: auth_data.info.email)
    @user.password = Devise.friendly_token[0,20]
    @user.save

    sign_in_and_redirect @user, event: :authentication
  end

  def failure
    flash.alert = 'Login failed.'
    redirect_to root_path
  end
end
