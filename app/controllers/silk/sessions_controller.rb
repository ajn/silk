class Silk::SessionsController < Silk::BaseController
  
  def new
    request_login!
    redirect_to root_path
  end

  def create
    @user_session = Silk::UserSession.new(params[:user])
    if @user_session.save
      flash[:notice] = "Hello #{@user_session.user.login}. You are now logged in"
      redirect_to session[:silk_return_url] && session.delete(:silk_return_url) || root_path
    else
      request_login!
      flash[:inline_error] = "Sorry. Incorrect username or password"
      redirect_to session[:silk_return_url] || root_path
    end
  end

  def destroy
    session[:silk_load] = true
    current_user_session.destroy
    flash[:notice] = "Thank you. You are now logged out"
    redirect_to root_path
  end
  
end