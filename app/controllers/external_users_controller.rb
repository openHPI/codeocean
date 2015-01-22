class ExternalUsersController < ApplicationController
  def authorize!
    authorize(@user || @users)
  end
  private :authorize!

  def index
    @users = ExternalUser.all
    authorize!
  end

  def show
    @user = ExternalUser.find(params[:id])
    authorize!
  end
end
