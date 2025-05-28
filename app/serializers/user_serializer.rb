# class UserSerializer
#   include JSONAPI::Serializer
#   attributes :id, :email, :first_name, :last_name, :country, :mobile_number, :created_at
# end

class UserSerializer
  include JSONAPI::Serializer

  attributes :id, :email, :first_name, :last_name, :country, :mobile_number, :created_at
  # rubocop:disable Style/IfUnlessModifier
  attribute :avatar_url do |user|
    if user.avatar.attached?
      Rails.application.routes.url_helpers.rails_blob_url(user.avatar, only_path: false)
    end
  end
  # rubocop:enable Style/IfUnlessModifier
end
