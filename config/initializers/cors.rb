Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'http://localhost:3000', 'http://localhost:3001'

    resource '*',
             headers: :any,
             expose: %w[access-token expiry token-type Authorization],
             methods: %i[get patch put delete post options],
             credentials: true
  end
end
