class EnrollmentsController < ApplicationController
  skip_before_action :authenticate_user_from_token!, only: [:create]
  before_action :authenticate_user!

  def create
    begin
      enrollment = current_user.enrollments.build(enrollment_params)
      
      if enrollment.save
        # Update course places_left
        enrollment.course.calculate_places_left
        enrollment.course.save
        
        render json: { 
          message: 'Successfully enrolled in the course',
          enrollment: {
            id: enrollment.id,
            course_id: enrollment.course_id,
            user_id: enrollment.user_id,
            created_at: enrollment.created_at
          }
        }, status: :created
      else
        render json: { errors: enrollment.errors.full_messages }, status: :unprocessable_entity
      end
    rescue StandardError => e
      Rails.logger.error "Enrollment creation error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      render json: { error: e.message, errors: [e.message] }, status: :internal_server_error
    end
  end

  private

  def enrollment_params
    params.permit(:course_id)
  end
end

