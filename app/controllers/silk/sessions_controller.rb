class Silk::SessionsController < Silk::BaseController
  
  def new
    request_login!
    redirect_to root_path
  end

  def create
    @user_session = Silk::UserSession.new(params[:user])
    if @user_session.save
      redirect_url = session[:silk_return_url] && session.delete(:silk_return_url) || root_path
      redirect_to redirect_url, :notice => "Hello #{@user_session.user.login}. You are now logged in"
    else
      request_login!
      flash[:inline_error] = "Sorry. Incorrect username or password"
      redirect_to session[:silk_return_url] || root_path
    end
  end

  def destroy
    session[:silk_load] = true
    current_user_session.destroy rescue nil
    redirect_to root_path, :notice => "Thank you. You are now logged out"
  end
  
end