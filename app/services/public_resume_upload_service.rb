# frozen_string_literal: true

class PublicResumeUploadService
  ALLOWED_CONTENT_TYPES = [
    "application/pdf",
    "application/msword",
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
  ].freeze

  ALLOWED_EXTENSIONS = %w[.pdf .doc .docx].freeze
  MAX_SIZE = 5.megabytes

  class Error < StandardError; end

  class << self
    def store!(file)
      raise Error, "No resume file provided" if file.blank?

      content_type = file.respond_to?(:content_type) ? file.content_type : nil
      original_filename = file.respond_to?(:original_filename) ? file.original_filename : "resume"
      extension = File.extname(original_filename).downcase

      unless ALLOWED_EXTENSIONS.include?(extension)
        raise Error, "Invalid file type. Only PDF and Word documents (.pdf, .doc, .docx) are allowed."
      end

      unless content_type.present? && ALLOWED_CONTENT_TYPES.include?(content_type)
        raise Error, "Invalid file type. Only PDF and Word documents are allowed."
      end

      file_size = file.respond_to?(:size) ? file.size : 0
      raise Error, "File size too large. Maximum size is 5MB." if file_size > MAX_SIZE

      filename = "resume_#{SecureRandom.uuid}#{extension}"
      uploads_dir = Rails.root.join("storage", "uploads")
      FileUtils.mkdir_p(uploads_dir)

      file_path = uploads_dir.join(filename)
      File.open(file_path, "wb") { |f| f.write(file.read) }

      "uploads/#{filename}"
    end
  end
end
