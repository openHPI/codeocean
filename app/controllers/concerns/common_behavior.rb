# frozen_string_literal: true

module CommonBehavior
  def create_and_respond(options = {})
    @object = options[:object]
    respond_to do |format|
      if @object.save
        notice = t('shared.object_created', model: @object.class.model_name.human)
        if block_given?
          result = yield
          notice = result if result.present?
        end
        path = options[:path].try(:call) || @object
        respond_with_valid_object(format, notice:, path:, status: :created)
      else
        respond_with_invalid_object(format, template: :new)
      end
    end
  end
  private :create_and_respond

  def destroy_and_respond(options = {})
    @object = options[:object]
    @object.destroy
    respond_to do |format|
      path = options[:path] || send(:"#{@object.class.model_name.collection}_path")
      format.html { redirect_to(path, notice: t('shared.object_destroyed', model: @object.class.model_name.human)) }
      format.json { head(:no_content) }
    end
  end
  private :destroy_and_respond

  def respond_with_invalid_object(format, options = {})
    format.html { render(options[:template]) }
    format.json { render(json: @object.errors, status: :unprocessable_entity) }
  end

  def respond_with_valid_object(format, options = {})
    format.html { redirect_to(options[:path], notice: options[:notice]) }
    format.json { render(:show, location: @object, status: options[:status]) }
  end
  private :respond_with_valid_object

  def update_and_respond(options = {})
    @object = options[:object]
    respond_to do |format|
      if @object.update(options[:params])
        notice = t('shared.object_updated', model: @object.class.model_name.human)
        if block_given?
          result = yield
          notice = result if result.present?
        end
        path = options[:path] || @object
        respond_with_valid_object(format, notice:, path:, status: :ok)
      else
        respond_with_invalid_object(format, template: :edit)
      end
    end
  end
  private :update_and_respond
end
