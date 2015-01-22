class ConsumersController < ApplicationController
  before_action :set_consumer, only: MEMBER_ACTIONS

  def authorize!
    authorize(@consumer || @consumers)
  end
  private :authorize!

  def create
    @consumer = Consumer.new(consumer_params)
    authorize!
    respond_to do |format|
      if @consumer.save
        format.html { redirect_to(@consumer, notice: t('shared.object_created', model: Consumer.model_name.human)) }
        format.json { render(:show, location: @consumer, status: :created) }
      else
        format.html { render(:new) }
        format.json { render(json: @consumer.errors, status: :unprocessable_entity) }
      end
    end
  end

  def destroy
    @consumer.destroy
    respond_to do |format|
      format.html { redirect_to(consumers_url, notice: t('shared.object_destroyed', model: Consumer.model_name.human)) }
      format.json { head(:no_content) }
    end
  end

  def edit
  end

  def consumer_params
    params[:consumer].permit(:name, :oauth_key, :oauth_secret)
  end
  private :consumer_params

  def index
    @consumers = Consumer.all
    authorize!
  end

  def new
    @consumer = Consumer.new(oauth_key: SecureRandom.hex, oauth_secret: SecureRandom.hex)
    authorize!
  end

  def set_consumer
    @consumer = Consumer.find(params[:id])
    authorize!
  end
  private :set_consumer

  def show
  end

  def update
    respond_to do |format|
      if @consumer.update(consumer_params)
        format.html { redirect_to(@consumer, notice: t('shared.object_updated', model: Consumer.model_name.human)) }
        format.json { render(:show, location: @consumer, status: :ok) }
      else
        format.html { render(:edit) }
        format.json { render(json: @consumer.errors, status: :unprocessable_entity) }
      end
    end
  end
end
