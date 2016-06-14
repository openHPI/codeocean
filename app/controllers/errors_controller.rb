class ErrorsController < ApplicationController
  before_action :set_execution_environment

  def authorize!
    authorize(@error || @errors)
  end
  private :authorize!

  def create
    @error = Error.new(error_params)
    authorize!
    hint = Whistleblower.new(execution_environment: @error.execution_environment).generate_hint(@error.message)
    respond_to do |format|
      format.json do
        if hint
          render(json: {hint: hint})
        else
          render(nothing: true, status: @error.save ? :created : :unprocessable_entity)
        end
      end
    end
  end

  def error_params
    params[:error].permit(:message, :submission_id).merge(execution_environment_id: @execution_environment.id)
  end
  private :error_params

  def index
    @errors = Error.for_execution_environment(@execution_environment).grouped_by_message.paginate(page: params[:page])
    authorize!
  end

  def set_execution_environment
    @execution_environment = ExecutionEnvironment.find(params[:execution_environment_id])
  end
  private :set_execution_environment

  def show
    @error = Error.find(params[:id])
    authorize!
  end
end
