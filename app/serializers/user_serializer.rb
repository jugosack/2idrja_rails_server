class UserSerializer
  include JSONAPI::Serializer
  attributes :id, :email, :first_name, :last_name, :country, :mobile_number,:created_at
end