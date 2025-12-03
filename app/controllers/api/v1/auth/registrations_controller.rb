module Api
  module V1
    module Auth
      class RegistrationsController < Devise::RegistrationsController
        respond_to :json

        def create
          build_resource(sign_up_params)

          resource.save
          yield resource if block_given?

          if resource.persisted?
            render json: {
              status: { code: 200, message: 'Signed up successfully.' },
              data: UserSerializer.new(resource).serializable_hash[:data][:attributes]
            }, status: :ok
          else
            clean_up_passwords resource
            set_minimum_password_length
            render json: {
              status: { message: "User couldn't be created successfully. #{resource.errors.full_messages.to_sentence}" },
              errors: resource.errors.full_messages
            }, status: :unprocessable_entity
          end
        end

        private

        def sign_up_params
          params.require(:user).permit(:email, :password, :password_confirmation, :name)
        end

        def account_update_params
          params.require(:user).permit(:email, :password, :password_confirmation, :current_password, :name)
        end
      end
    end
  end
end
