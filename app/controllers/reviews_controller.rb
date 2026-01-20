class ReviewsController < ApplicationController
  include Rails.application.routes.url_helpers

  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user_from_token!, only: [:index]
  before_action :authenticate_user!, only: [:create]

  # GET /reviews
  def index
    reviews = Review.includes(user: { avatar_attachment: :blob }, course: {})
                    .order(created_at: :desc)

    render json: reviews.map { |review|
      review.as_json.merge(
        user: review.user.as_json(only: [:id, :first_name, :last_name]).merge(
          avatar_url: review.user.avatar.attached? ? url_for(review.user.avatar) : nil
        ),
        course: review.course.as_json(only: [:id, :course_name])
      )
    }
  end

  # POST /reviews
  def create
    review = current_user.reviews.new(review_params)

    if review.save
      update_course_rating(review.course)
      render json: review, status: :created
    else
      render json: { errors: review.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def review_params
    params.require(:review).permit(
      :course_id,
      :title,
      :body,
      :rating,
      flags: [:structured, :engaging, :knowledgeable]
    )
  end

  def update_course_rating(course)
    course.update!(rating: course.reviews.average(:rating))
  end
end
