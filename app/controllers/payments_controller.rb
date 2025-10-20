class PaymentsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: %i[create_payment_intent confirm webhook]
  # POST /payments/create_payment_intent
  def create_payment_intent
    amount = params[:amount].to_i

    payment_intent = Stripe::PaymentIntent.create({
                                                    amount: amount,
                                                    currency: 'usd',
                                                    metadata: {
                                                      course_id: params[:course_id],
                                                      student_id: params[:student_id]
                                                    }
                                                  })

    # Record payment in DB
    Payment.create!(
      user_id: params[:student_id],
      course_id: params[:course_id],
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
    course = Course.find(params[:course_id])
    student = User.find(params[:student_id])

    return render json: { error: 'Course is already full' }, status: :unprocessable_entity if course.places_left <= 0

    enrollment = Enrollment.new(course: course, user: student)
    if enrollment.save
      render json: { message: 'Payment confirmed and student enrolled successfully!' }, status: :ok
    else
      render json: { error: enrollment.errors.full_messages }, status: :unprocessable_entity
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
