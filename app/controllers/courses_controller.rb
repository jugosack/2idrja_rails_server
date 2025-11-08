# class CoursesController < ApplicationController
#   before_action :authenticate_user!, except: [:index]
#     before_action :set_course, only: [:show, :edit, :update, :destroy, :upload_image]
#     before_action :authorize_admin!, only: [:new, :create, :edit, :update, :destroy, :upload_image]
#     skip_before_action :verify_authenticity_token, only: [:create, :upload_image, :update, :destroy]

class CoursesController < ApplicationController
  skip_before_action :authenticate_user_from_token!, only: [:index]
  before_action :authenticate_user!, except: [:index]
  before_action :set_course, only: %i[show edit update destroy upload_image]
  before_action :authorize_admin!, only: %i[new create edit update destroy upload_image]
  skip_before_action :verify_authenticity_token, only: %i[create upload_image update destroy]

  # GET /courses
  def index
    @courses = Course.all
    render json: @courses.map { |course| CourseSerializer.new(course).serializable_hash[:data][:attributes] }
  end

  # GET /courses/:id
  def show
    render json: CourseSerializer.new(@course).serializable_hash[:data][:attributes]
  end

  # GET /courses/new
  def new
    @course = Course.new
  end

  def create
    begin
      @course = current_user.courses.build(course_params)
      if @course.save
        render json: { message: 'Course created successfully', course: CourseSerializer.new(@course).serializable_hash[:data][:attributes] }
      else
        render json: { errors: @course.errors.full_messages }, status: :unprocessable_entity
      end
    rescue StandardError => e
      Rails.logger.error "Course creation error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      render json: { error: e.message, errors: [e.message] }, status: :internal_server_error
    end
  end

  def update
    if @course.update(course_params)
      render json: { message: 'Course updated successfully', course: CourseSerializer.new(@course).serializable_hash[:data][:attributes] }
    else
      render json: { errors: @course.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # POST /courses/:id/upload_image
  def upload_image
    if params[:image].present?
      @course.image.attach(params[:image])
      if @course.image.attached?
        render json: {
          message: 'Image uploaded successfully',
          image_url: rails_blob_url(@course.image, only_path: false),
          course: CourseSerializer.new(@course).serializable_hash[:data][:attributes]
        }
      else
        render json: { error: 'Failed to attach image' }, status: :unprocessable_entity
      end
    else
      render json: { error: 'No image provided' }, status: :bad_request
    end
  end

  # GET /courses/:id/edit
  def edit; end

  # DELETE /courses/:id
  def destroy
    @course.destroy
    render json: { message: 'Course deleted successfully' }, status: :ok
  end

  # GET /users/:user_id/enrolled_courses
  def enrolled_courses
    # Ensure user can only see their own enrolled courses
    user_id = params[:user_id].to_i
    if current_user.id != user_id
      render json: { error: 'Unauthorized' }, status: :forbidden
      return
    end

    user = current_user
    enrollments = user.enrollments.includes(:course)

    courses = enrollments.map do |enrollment|
      course_data = CourseSerializer.new(enrollment.course).serializable_hash[:data][:attributes]
      course_data.merge({
                          enrollment_id: enrollment.id,
                          enrolled_at: enrollment.created_at
                        })
    end

    render json: courses
  end

  private

  def set_course
    @course = Course.find(params[:id])
  end

  def authorize_admin!
    return if current_user.admin?

    render json: { error: 'Unauthorized. Admin access only.' }, status: :forbidden
  end

  def course_params
    params.require(:course).permit(
      :course_name, :start_date, :end_date, :description,
      :benefits, :target_audience, :additional_info, :fee,
      :max_students, :enrolled_students, :course_status, :rating, :general_description
    )
  end
end
