module AuthHelper
  def auth_headers(user)
    token = JWT.encode(
      { sub: user.id, scp: 'user', exp: 24.hours.from_now.to_i },
      ENV['DEVISE_JWT_SECRET_KEY']
    )
    { 'Authorization' => "Bearer #{token}" }
  end
end

RSpec.configure do |config|
  config.include AuthHelper, type: :request
end
