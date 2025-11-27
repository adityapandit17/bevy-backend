class PolicyDocument < ApplicationRecord
  belongs_to :uploader, class_name: "User", foreign_key: "uploaded_by", optional: true

  # Validations
  validates :title, presence: true
  validates :category, presence: true
  validates :file_path, presence: true
  validates :status, presence: true, inclusion: { in: %w[active expired expiring] }
  validates :file_size, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # Scopes
  scope :active, -> { where(status: "active") }
  scope :expired, -> { where(status: "expired") }
  scope :expiring, -> { where(status: "expiring") }
  scope :by_category, ->(category) { where(category: category) }
  scope :expiring_soon, -> { where("expiry_date BETWEEN ? AND ?", Date.current, Date.current + 30.days) }
  scope :expired_documents, -> { where("expiry_date < ?", Date.current) }

  # Callbacks
  before_save :update_last_updated, :check_expiry_status

  # Helper methods
  def active?
    status == "active"
  end

  def expired?
    status == "expired"
  end

  def expiring?
    status == "expiring"
  end

  def is_expired?
    expiry_date.present? && expiry_date < Date.current
  end

  def is_expiring_soon?
    expiry_date.present? && expiry_date.between?(Date.current, Date.current + 30.days)
  end

  def days_until_expiry
    return nil unless expiry_date

    (expiry_date - Date.current).to_i
  end

  def formatted_last_updated
    last_updated&.strftime("%d/%m/%Y") || created_at.strftime("%d/%m/%Y")
  end

  def formatted_expiry_date
    expiry_date&.strftime("%d/%m/%Y") || "No expiry"
  end

  def file_size_formatted
    # Convert bytes to human readable format
    size = file_size.to_i
    if size < 1024
      "#{size} B"
    elsif size < 1024 * 1024
      "#{(size / 1024.0).round(1)} KB"
    else
      "#{(size / (1024.0 * 1024.0)).round(1)} MB"
    end
  end

  def increment_downloads!
    increment!(:downloads)
  end

  private

  def update_last_updated
    self.last_updated = Date.current if changed?
  end

  def check_expiry_status
    if expiry_date.present?
      if expiry_date < Date.current
        self.status = "expired"
      elsif expiry_date.between?(Date.current, Date.current + 30.days)
        self.status = "expiring" unless status == "expired"
      else
        self.status = "active" unless status == "expired"
      end
    end
  end
end
