class ConversationsController < ApplicationController
  # before_action :authenticate_user!
  skip_before_action :verify_authenticity_token

  before_action :set_course, only: %i[index private]
  before_action :set_conversation, only: :show

  # GET /courses/:course_id/conversations
  def index
    participant_ids = ConversationParticipant
                      .where(user: current_user)
                      .select(:conversation_id)

    conversations = @course.conversations
                           .where(id: participant_ids)
                           .includes(:participants, :last_message, :course)

    render json: conversations.as_json(
      include: {
        course: {
          only: %i[id course_name]
        },
        participants: {
          only: %i[id first_name last_name email]
        },
        last_message: {
          only: %i[id body created_at user_id]
        }
      }
    )
  end

  # GET /conversations/:id
  def show
    return render json: { error: 'Forbidden' }, status: :forbidden unless @conversation.participant?(current_user)

    render json: @conversation.as_json(
      include: {
        course: {
          only: %i[id course_name]
        },
        participants: {
          only: %i[id first_name last_name email]
        },
        messages: {
          include: {
            user: {
              only: %i[id first_name last_name]
            }
          }
        }
      }
    )
  end

  # POST /courses/:course_id/conversations/private
  def private
    receiver = User.find(params[:user_id])

    conversation = Conversation.find_or_create_private(
      @course,
      current_user,
      receiver
    )

    render json: conversation.as_json(
      only: %i[id course_id conversation_type created_at updated_at],
      include: {
        course: {
          only: %i[id course_name]
        },
        participants: {
          only: %i[id first_name last_name email]
        }
      }
    ), status: :created
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'User not found' }, status: :not_found
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def set_course
    @course = Course.find(params[:course_id])
  end

  def set_conversation
    @conversation = Conversation.find(params[:id])
  end
end
