module Api
  module V1
    module Auth
      class SessionsController < Devise::SessionsController
        respond_to :json
        before_action :configure_sign_in_params, only: [:create]

        def create
          user = User.find_by(email: sign_in_params[:email])

          if user&.valid_password?(sign_in_params[:password])
            sign_in(user, store: false)
            render json: {
              status: { code: 200, message: 'Logged in successfully.' },
              data: UserSerializer.new(user).serializable_hash[:data][:attributes]
            }, status: :ok
          else
            render json: {
              status: { code: 401, message: 'Invalid email or password.' }
            }, status: :unauthorized
          end
        end

        def destroy
          render json: {
            status: { code: 200, message: 'Logged out successfully.' }
          }, status: :ok
        end

        private

        def sign_in_params
          params.require(:user).permit(:email, :password)
        end

        def configure_sign_in_params
          devise_parameter_sanitizer.permit(:sign_in, keys: [:email, :password])
        end

        def respond_with(resource, _opts = {})
          render json: {
            status: { code: 200, message: 'Logged in successfully.' },
            data: UserSerializer.new(resource).serializable_hash[:data][:attributes]
          }, status: :ok
        end

        def respond_to_on_destroy
          render json: {
            status: { code: 200, message: 'Logged out successfully.' }
          }, status: :ok
        end
      end
    end
  end
end
