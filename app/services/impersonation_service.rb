# frozen_string_literal: true

class ImpersonationService
  class Error < StandardError; end

  IMPERSONATION_EXPIRATION = 2.hours

  def self.feature_enabled?(company)
    return false unless company

    CompanyFeatureFlag.for_company(company)["impersonation"] == true
  end

  def self.find_company_admin(company)
    role_ids = Role.system_roles.where(name: "Super Admin").or(
      Role.where(company_id: company.id, name: "Super Admin")
    ).pluck(:id)

    return nil if role_ids.empty?

    company.users.active
           .joins(:user_roles)
           .where(user_roles: { role_id: role_ids })
           .order(:id)
           .first
  end

  # Tenant Super Admin → another user in the same company
  def self.start_tenant!(actor:, target_user:)
    raise Error, "Only company Super Admins can impersonate users" unless actor.super_admin?
    raise Error, "Impersonation is not enabled for this company" unless feature_enabled?(actor.company)
    raise Error, "Target user is required" unless target_user
    raise Error, "Cannot impersonate yourself" if target_user.id == actor.id
    raise Error, "Target user must belong to your company" if target_user.company_id != actor.company_id
    raise Error, "Target user is not active" unless target_user.active?

    token = JwtService.generate_impersonation_token(
      target_user,
      impersonator_id: actor.id,
      expires_in: IMPERSONATION_EXPIRATION
    )

    {
      token: token,
      user: target_user,
      company: target_user.company,
      impersonation: impersonation_meta(impersonator: actor, platform: false)
    }
  end

  # Platform admin → company Super Admin (or specific user in that company)
  def self.start_platform!(platform_admin:, company:, target_user: nil)
    raise Error, "Company is required" unless company

    target = target_user || find_company_admin(company)
    raise Error, "No active Super Admin found for this company" unless target
    raise Error, "Target user must belong to this company" if target.company_id != company.id
    raise Error, "Target user is not active" unless target.active?

    token = JwtService.generate_impersonation_token(
      target,
      platform_admin_id: platform_admin.id,
      expires_in: IMPERSONATION_EXPIRATION
    )

    {
      token: token,
      user: target,
      company: company,
      redirect_url: build_redirect_url(token),
      impersonation: impersonation_meta(platform_admin: platform_admin, platform: true)
    }
  end

  def self.stop!(payload:)
    raise Error, "Not currently impersonating" unless JwtService.impersonating?(payload)

    if payload["platform_admin_id"].present?
      return { platform: true, message: "Platform impersonation ended. Close this tab and return to Bevy Admin." }
    end

    impersonator_id = payload["impersonator_id"]
    raise Error, "Invalid impersonation token" if impersonator_id.blank?

    actor = User.includes(:company, roles: :permissions).find_by(id: impersonator_id)
    raise Error, "Original admin account is no longer available" unless actor&.active?

    token = JwtService.generate_token(actor)
    {
      platform: false,
      token: token,
      user: actor,
      company: actor.company
    }
  end

  def self.impersonation_meta(impersonator: nil, platform_admin: nil, platform: false)
    {
      active: true,
      platform: platform,
      impersonator: if impersonator
                      { id: impersonator.id, name: impersonator.name, email: impersonator.email }
                    elsif platform_admin
                      { id: platform_admin.id, name: platform_admin.name, email: platform_admin.email, type: "platform" }
                    end
    }
  end

  def self.meta_from_payload(payload)
    return { active: false } unless JwtService.impersonating?(payload)

    if payload["platform_admin_id"].present?
      admin = PlatformAdminUser.find_by(id: payload["platform_admin_id"])
      return impersonation_meta(platform_admin: admin, platform: true) if admin

      return { active: true, platform: true, impersonator: nil }
    end

    actor = User.find_by(id: payload["impersonator_id"])
    impersonation_meta(impersonator: actor, platform: false)
  end

  def self.build_redirect_url(token)
    base = PlatformSetting.get("tenant_app_url").to_s.chomp("/")
    base = "http://localhost:3001" if base.blank?
    "#{base}/impersonation/accept#token=#{CGI.escape(token)}"
  end
  private_class_method :build_redirect_url
end
