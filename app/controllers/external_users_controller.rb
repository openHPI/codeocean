class ExternalUsersController < ApplicationController
  def authorize!
    authorize(@user || @users)
  end
  private :authorize!

  def index
    @users = ExternalUser.all.includes(:consumer).paginate(page: params[:page])
    authorize!
  end

  def show
    @user = ExternalUser.find(params[:id])
    authorize!
  end

  def statistics
    @user = ExternalUser.find(params[:id])
    authorize!
  end

end
