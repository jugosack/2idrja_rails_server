# app/serializers/course_serializer.rb
class CourseSerializer
  include JSONAPI::Serializer
  include Rails.application.routes.url_helpers

  attributes :id, :course_name, :start_date, :end_date, :description,
             :benefits, :target_audience, :additional_info, :fee,
             :max_students, :enrolled_students, :places_left,
             :course_status, :rating, :user_id, :general_description

  attribute :image_url do |course|
    course.image.attached? ? Rails.application.routes.url_helpers.rails_blob_url(course.image, only_path: false) : nil
  end
end
