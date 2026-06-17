# frozen_string_literal: true

class Company < ApplicationRecord
  DASHBOARD_LAYOUTS = %w[top_nav sidebar].freeze

  LOGO_CONTENT_TYPES = %w[image/png image/jpeg image/jpg image/webp image/svg+xml].freeze
  LOGO_MAX_SIZE = 2.megabytes

  validates :dashboard_layout, inclusion: { in: DASHBOARD_LAYOUTS }

  has_one_attached :logo

  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :code, presence: true, uniqueness: true, length: { minimum: 2, maximum: 10 }
  validates :industry, presence: true
  validates :employee_count, presence: true
  validates :timezone, presence: true
  validates :currency, presence: true, length: { is: 3 }
  validates :country_code, allow_nil: true, allow_blank: true, length: { is: 2 }
  validates :careers_slug, uniqueness: true, allow_nil: true

  before_validation :ensure_careers_slug

  scope :by_industry, ->(industry) { where(industry: industry) }
  scope :large_companies, -> { where("CAST(employee_count AS INTEGER) > ?", 1000) }
  scope :small_companies, -> { where("CAST(employee_count AS INTEGER) <= ?", 100) }

  def self.current
    first
  end

  def self.dashboard_layout_for_current
    current&.dashboard_layout.presence || "top_nav"
  end

  def formatted_employee_count
    "#{employee_count} employees"
  end

  def display_name
    "#{name} (#{code})"
  end

  def google_calendar_connected?
    google_calendar_refresh_token.present?
  end

  def careers_page_url
    return nil if careers_slug.blank?

    base = ENV.fetch("FRONTEND_URL", "http://localhost:3001").chomp("/")
    "#{base}/careers/#{careers_slug}"
  end

  def public_job_url(job)
    return nil unless careers_slug.present? && job.public_slug.present? && job.publicly_available?

    "#{careers_page_url}/#{job.public_slug}"
  end

  def logo_url
    BlobUrl.for(logo)
  end

  def attach_logo!(file)
    raise ArgumentError, "No logo file provided" if file.blank?

    content_type = file.respond_to?(:content_type) ? file.content_type : nil
    if content_type.present? && LOGO_CONTENT_TYPES.exclude?(content_type)
      raise ArgumentError, "Invalid file type. Only PNG, JPG, WEBP, or SVG images are allowed."
    end

    file_size = file.respond_to?(:size) ? file.size : 0
    raise ArgumentError, "File size too large. Maximum size is 2MB." if file_size > LOGO_MAX_SIZE

    logo.purge if logo.attached?
    logo.attach(file)
  end

  def remove_logo!
    logo.purge if logo.attached?
  end

  private

  def ensure_careers_slug
    if careers_slug.blank?
      self.careers_slug = unique_slug_from(name)
      return
    end

    return unless name_changed? && name_was.present?

    previous_auto_slug = unique_slug_from(name_was, exclude_id: id)
    self.careers_slug = unique_slug_from(name) if careers_slug == previous_auto_slug
  end

  def unique_slug_from(company_name, exclude_id: nil)
    base = company_name.to_s.parameterize.presence || "company"
    candidate_slug = base
    suffix = 0

    scope = Company.all
    scope = scope.where.not(id: exclude_id) if exclude_id.present?

    while scope.exists?(careers_slug: candidate_slug)
      suffix += 1
      candidate_slug = "#{base}-#{suffix}"
    end

    candidate_slug
  end
end
