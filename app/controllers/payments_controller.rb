class PaymentsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: %i[create_payment_intent confirm webhook]
  # POST /payments/create_payment_intent
  def create_payment_intent
    course_id = params[:course_id]
    student_id = params[:student_id]
    amount = params[:amount].to_i

    # Security: Verify that student_id matches the logged-in user
    unless current_user && current_user.id.to_s == student_id.to_s
      Rails.logger.warn "Payment intent creation: user_id mismatch. Current user: #{current_user&.id}, Provided student_id: #{student_id}"
      return render json: { error: 'Unauthorized: You can only create payments for yourself' }, status: :forbidden
    end

    # 1️⃣ Check if user is already enrolled in the course (use current_user.id for security)
    if Enrollment.exists?(course_id: course_id, user_id: current_user.id)
      return render json: { error: 'You are already enrolled in this course.' }, status: :unprocessable_entity
    end

    # 2️⃣ Check if user already has a pending or succeeded payment for this course (use current_user.id for security)
    existing_payment = Payment.find_by(course_id: course_id, user_id: current_user.id, status: %w[pending succeeded])
    if existing_payment
      return render json: { error: 'A payment for this course already exists or is being processed.' }, status: :unprocessable_entity
    end

    # 3️⃣ Check if course has available spots
    course = Course.find(course_id)
    return render json: { error: 'Course is already full.' }, status: :unprocessable_entity if course.places_left <= 0

    # 4️⃣ Create Stripe PaymentIntent
    payment_intent = Stripe::PaymentIntent.create(
      amount: amount,
      currency: 'usd',
      metadata: {
        course_id: course_id,
        student_id: student_id
      }
    )

    # 5️⃣ Record new payment in DB (use current_user.id for security)
    Payment.create!(
      user_id: current_user.id,
      course_id: course_id,
      amount: amount,
      currency: 'usd',
      stripe_payment_intent_id: payment_intent.id,
      status: 'pending'
    )

    render json: { client_secret: payment_intent.client_secret }
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # POST /payments/confirm
  def confirm
    course_id = params[:course_id]
    student_id = params[:student_id]

    begin
      # Security: Verify that student_id matches the logged-in user
      unless current_user && current_user.id.to_s == student_id.to_s
        Rails.logger.warn "Enrollment attempt: user_id mismatch. Current user: #{current_user&.id}, Provided student_id: #{student_id}"
        return render json: { error: 'Unauthorized: You can only enroll as yourself' }, status: :forbidden
      end

      course = Course.find(course_id)
      student = current_user # Use current_user instead of finding by student_id

      # Check if course is full
      if course.places_left <= 0
        return render json: { error: 'Course is already full' }, status: :unprocessable_entity
      end

      # Check if already enrolled (use current_user.id for security)
      existing_enrollment = Enrollment.find_by(course_id: course_id, user_id: current_user.id)
      if existing_enrollment
        # Already enrolled, but still update payment status
        payment = Payment.find_by(course_id: course_id, user_id: current_user.id, status: 'pending')
        payment&.update!(status: 'succeeded')
        Rails.logger.info "User #{current_user.id} already enrolled in course #{course_id}"
        return render json: { 
          message: 'Already enrolled in this course',
          enrollment: {
            id: existing_enrollment.id,
            course_id: existing_enrollment.course_id,
            user_id: existing_enrollment.user_id
          }
        }, status: :ok
      end

      # Create new enrollment (use current_user for security)
      enrollment = Enrollment.new(course: course, user: current_user)
      
      if enrollment.save
        Rails.logger.info "Successfully created enrollment: user_id=#{current_user.id}, course_id=#{course_id}, enrollment_id=#{enrollment.id}"
        
        # Update payment status to succeeded (use current_user.id for security)
        payment = Payment.find_by(course_id: course_id, user_id: current_user.id, status: 'pending')
        if payment
          payment.update!(status: 'succeeded')
          Rails.logger.info "Updated payment status to succeeded for payment_id=#{payment.id}"
        else
          # Payment might not exist, create it for record keeping
          Rails.logger.warn "Payment record not found for course_id: #{course_id}, user_id: #{current_user.id}"
        end

        render json: { 
          message: 'Payment confirmed and student enrolled successfully!',
          enrollment: {
            id: enrollment.id,
            course_id: enrollment.course_id,
            user_id: enrollment.user_id,
            created_at: enrollment.created_at
          }
        }, status: :ok
      else
        Rails.logger.error "Failed to create enrollment: #{enrollment.errors.full_messages.join(', ')}"
        render json: { 
          error: 'Failed to create enrollment',
          errors: enrollment.errors.full_messages 
        }, status: :unprocessable_entity
      end
    rescue ActiveRecord::RecordNotFound => e
      render json: { error: "Record not found: #{e.message}" }, status: :not_found
    rescue StandardError => e
      Rails.logger.error "Enrollment confirmation error: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      render json: { error: e.message }, status: :internal_server_error
    end
  end

  # POST /payments/webhook
  def webhook
    payload = request.body.read

    begin
      event = Stripe::Event.construct_from(JSON.parse(payload))
    rescue JSON::ParserError
      return render json: { error: 'Invalid payload' }, status: 400
    end

    if event.type == 'payment_intent.succeeded'
      payment_intent = event.data.object
      course_id = payment_intent.metadata.course_id
      student_id = payment_intent.metadata.student_id

      payment = Payment.find_by(stripe_payment_intent_id: payment_intent.id)
      payment&.update!(status: 'succeeded')

      course = Course.find_by(id: course_id)
      student = User.find_by(id: student_id)

      Enrollment.find_or_create_by(course: course, user: student) if course && student
    elsif event.type == 'payment_intent.payment_failed'
      payment_intent = event.data.object
      payment = Payment.find_by(stripe_payment_intent_id: payment_intent.id)
      payment&.update!(status: 'failed')
    end

    render json: { message: 'Received' }, status: :ok
  end
end
