class EnrollmentMailer < ApplicationMailer
  default from: 'no-reply@yourapp.com'

  def enrollment_confirmation(enrollment)
    @enrollment = enrollment
    @user = enrollment.user
    @course = enrollment.course

    mail(
      to: @user.email,
      subject: "Enrollment confirmation for #{@course.course_name}"
    )
  end

  def admin_notification(enrollment)
    @enrollment = enrollment
    @user = enrollment.user
    @course = enrollment.course

    admins = User.where(role: 'admin').pluck(:email)
    return if admins.empty?  # prevent errors if no admin exists

    mail(
      to: admins,
      subject: "New enrollment: #{@user.email} joined #{@course.course_name}"
    )
  end
end
