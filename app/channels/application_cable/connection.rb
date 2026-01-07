module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      # Extract token from query string or headers
      token = request.params[:token] || extract_token_from_headers

      if token.blank?
        reject_unauthorized_connection
        return
      end

      user = JwtService.verify_token(token)

      if user&.active?
        user
      else
        reject_unauthorized_connection
      end
    end

    def extract_token_from_headers
      auth_header = request.headers["Authorization"] || request.headers["authorization"]
      return nil unless auth_header

      auth_header.split(" ").last if auth_header.start_with?("Bearer ")
    end
  end
end
