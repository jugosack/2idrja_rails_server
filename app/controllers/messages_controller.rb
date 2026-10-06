class MessagesController < ApplicationController
  skip_before_action :verify_authenticity_token

  # before_action :authenticate_user!
  before_action :set_conversation

  # GET /conversations/:conversation_id/messages
  def index
    return forbidden unless @conversation.participant?(current_user)

    render json: @conversation.messages.includes(:user).map { |message|
      serialize_message(message)
    }
  end

  # POST /conversations/:conversation_id/messages
  def create
    return forbidden unless @conversation.participant?(current_user)

    message = @conversation.messages.new(message_params)
    message.user = current_user

    if message.save
      render json: serialize_message(message), status: :created
    else
      render json: {
        errors: message.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # PATCH /conversations/:conversation_id/messages/:id
  def update
    return forbidden unless @conversation.participant?(current_user)

    message = @conversation.messages.find(params[:id])

    unless message.user_id == current_user.id
      return render json: {
        error: 'You can only edit your own messages'
      }, status: :forbidden
    end

    if message.update(message_params)
      render json: serialize_message(message), status: :ok
    else
      render json: {
        errors: message.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # DELETE /conversations/:conversation_id/messages/:id
  def destroy
    return forbidden unless @conversation.participant?(current_user)

    message = @conversation.messages.find(params[:id])

    unless message.user_id == current_user.id
      return render json: {
        error: 'You can only delete your own messages'
      }, status: :forbidden
    end

    message.destroy!

    head :no_content
  end

  private

  def set_conversation
    @conversation = Conversation.find(params[:conversation_id])
  end

  def message_params
    params.permit(:body, files: [])
  end

  def forbidden
    render json: {
      error: 'Forbidden'
    }, status: :forbidden
  end

  def serialize_message(message)
    {
      id: message.id,
      body: message.body,
      created_at: message.created_at,
      user: {
        id: message.user.id,
        first_name: message.user.first_name,
        last_name: message.user.last_name
      },
      files: message.files.map do |file|
        {
          id: file.id,
          filename: file.filename.to_s,
          content_type: file.content_type,
          byte_size: file.byte_size,
          url: url_for(file)
        }
      end
    }
  end
end
