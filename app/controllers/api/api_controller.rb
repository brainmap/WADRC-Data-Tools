

class InvalidToken < RuntimeError
	def initialize(message:)
		@message = message
	end
	attr_reader :message
end

class MissingToken < RuntimeError
	def initialize(message:)
		@message = message
	end
	attr_reader :message
end

class UnpermittedParameterValue < RuntimeError
	def initialize(parameter:, value:)
		@parameter = parameter
		@value = value
	end
	attr_reader :parameter, :value
end

class JsonWebToken
  # secret to encode and decode token
  #HMAC_SECRET = Rails.application.secrets.secret_key_base

  def self.decode(token)
    api_key = ApiKey.find_by_access_token(token)
    if api_key.nil?
      raise InvalidToken.new(message:"Invalid token: Couldn't find ApiKey with token='#{token}'")
    end
    return api_key
  end
end

class AuthorizeApiRequest
	include Response

	def initialize(headers = {})
		@headers = headers
	end

	# Service entry point - return valid user object
	def call
		{user: user}
	end

	private

	attr_reader :headers

	def user
		# check if user is in the database
		# memoize user object
		# puts "#{decoded_auth_token.to_s}"
		@user ||= User.find(decoded_auth_token.user.id) if decoded_auth_token

	end

		# decode authentication token
	def decoded_auth_token
		#puts "the token is #{http_auth_header}"
		@decoded_auth_token ||= JsonWebToken.decode(http_auth_header)
	end

	# check for token in `Authorization` header
	def http_auth_header
	   	if headers['Authorization'].present?
	   		return headers['Authorization'].split(' ').last
	   	end
	   	raise MissingToken.new(message:"Missing token. Please provide a security token.")
	end
end

	
class API::APIController  < ActionController::API
	before_action :authorize_my_request
	rescue_from InvalidToken, with: :invalid_token
	rescue_from MissingToken, with: :missing_token
	attr_reader :current_user

	private

	def authorize_my_request
		# puts "now we're authorizing"
		@current_user = (AuthorizeApiRequest.new(request.headers).call)[:user]
		# if !@current_user.nil?
		# 	puts "the user is #{@current_user.id}"
		# else
		# 	puts "the user is nil!"
		# end
		@current_user
	end	

	def invalid_parameters(exception) 
		render json: { errors: { exception.parameter => "Value '#{ exception.value }' is not supported value for the parameter '#{ exception.parameter }'." } }, status: 400
	end 
	def missing_token(exception) 
		render json: { errors: { "MissingToken" => exception.message } }, status: :unauthorized
	end 
	def invalid_token(exception) 
		render json: { errors: { "InvalidToken" => exception.message } }, status: 422
	end 
end

