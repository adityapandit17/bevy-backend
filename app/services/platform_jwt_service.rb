# frozen_string_literal: true

class PlatformJwtService
  SECRET_KEY = JwtService::SECRET_KEY
  EXPIRATION_TIME = JwtService::EXPIRATION_TIME
  AUDIENCE = "platform"

  class << self
    def generate_token(admin_user)
      payload = {
        aud: AUDIENCE,
        admin_user_id: admin_user.id,
        email: admin_user.email,
        name: admin_user.name,
        role: admin_user.role,
        iat: Time.current.to_i,
        jti: SecureRandom.uuid
      }
      JwtService.encode(payload)
    end

    def verify_token(token)
      return nil if token.blank?

      payload = JwtService.decode(token)
      return nil unless payload
      return nil unless payload["aud"] == AUDIENCE
      return nil if payload["exp"] && Time.current.to_i > payload["exp"]

      admin = PlatformAdminUser.find_by(id: payload["admin_user_id"])
      return nil unless admin&.active?

      admin.update_last_login!
      admin
    end
  end
end
