class InstructorsController < ApplicationController
  protect_from_forgery with: :null_session

  skip_before_action :authenticate_user_from_token!, only: %i[index show]

  before_action :authenticate_user!  # Devise authentication
  before_action :authorize_admin!, only: %i[create update destroy]
  before_action :set_instructor, only: %i[show update destroy]

  def index
    instructors = Instructor.all
    render json: instructors.map { |instructor| instructor_response(instructor) }
  end

  def show
    render json: instructor_response(@instructor)
  end

  def create
    instructor = Instructor.new(instructor_params)
    instructor.profile_pic.attach(params[:profile_pic]) if params[:profile_pic]

    if instructor.save
      render json: instructor_response(instructor), status: :created
    else
      render json: instructor.errors, status: :unprocessable_entity
    end
  end

  def update
    if @instructor.update(instructor_params)
      @instructor.profile_pic.attach(params[:profile_pic]) if params[:profile_pic]
      render json: instructor_response(@instructor)
    else
      render json: @instructor.errors, status: :unprocessable_entity
    end
  end

  def destroy
    @instructor.destroy
    head :no_content
  end

  private

  def set_instructor
    @instructor = Instructor.find(params[:id])
  end

  def instructor_params
    # Adjust this if your frontend sends nested params under :instructor
    params.permit(:first_name, :last_name, :course_name, :description, :expertise, :email)
  end

  def instructor_response(instructor)
    {
      id: instructor.id,
      first_name: instructor.first_name,
      last_name: instructor.last_name,
      email: instructor.email,
      course_name: instructor.course_name,
      description: instructor.description,
      expertise: instructor.expertise,
      profile_pic_url: instructor.profile_pic.attached? ? url_for(instructor.profile_pic) : nil
    }
  end

  def authorize_admin!
    Rails.logger.info "authorize_admin! current_user role: #{current_user&.role.inspect}"
    return if current_user&.role == 'admin'

    render json: { error: 'Access denied: Admins only' }, status: :forbidden
    nil
  end
end
