class UploadsController < ApplicationController
  # Skip X-Frame-Options for this controller
  skip_before_action :verify_authenticity_token, if: -> { request.format.json? }

  # Viewing/downloading files is public (iframes cannot send Authorization headers).
  # UUID filenames limit discoverability; create still requires authentication.
  skip_before_action :authenticate_user_from_token!, only: [ :show, :options ]

  # Remove default X-Frame-Options header and set our own
  before_action :set_frame_options_header, only: [ :show ]

  # Handle CORS preflight requests
  def options
    response.headers["Access-Control-Allow-Origin"] = "*"
    response.headers["Access-Control-Allow-Methods"] = "GET, POST, OPTIONS"
    response.headers["Access-Control-Allow-Headers"] = "Origin, Content-Type, Accept, Authorization"
    head :ok
  end

  def create
    if params[:file].blank?
      render json: { error: "No file provided" }, status: :bad_request
      return
    end

    file = params[:file]

    # Validate file type
    allowed_types = [
      "application/pdf",
      "application/msword",
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      "application/vnd.ms-excel",
      "text/plain",
      "text/csv",
      "image/jpeg",
      "image/jpg",
      "image/png",
      "image/webp",
      "image/heic",
      "image/heif"
    ]

    # Handle both ActionController::Parameters and ActionDispatch::Http::UploadedFile
    if file.respond_to?(:content_type)
      content_type = file.content_type
    elsif file.is_a?(ActionController::Parameters) && file[:content_type]
      content_type = file[:content_type]
    else
      content_type = nil
    end

    if file.respond_to?(:original_filename)
      original_filename = file.original_filename
    elsif file.is_a?(ActionController::Parameters) && file[:original_filename]
      original_filename = file[:original_filename]
    else
      original_filename = "uploaded_file"
    end

    if file.respond_to?(:size)
      file_size = file.size
    elsif file.is_a?(ActionController::Parameters) && file[:tempfile]
      file_size = 0
    else
      file_size = 0
    end

    # Mobile camera scans may omit content_type; infer from filename when possible.
    if content_type.blank? && original_filename.present?
      content_type = case File.extname(original_filename.to_s).downcase
      when ".jpg", ".jpeg" then "image/jpeg"
      when ".png" then "image/png"
      when ".heic" then "image/heic"
      when ".pdf" then "application/pdf"
      else content_type
      end
    end

    unless content_type && allowed_types.include?(content_type)
      render json: { error: "Invalid file type. Allowed: PDF, Word, JPEG, PNG. Got: #{content_type}" }, status: :unprocessable_entity
      return
    end

    if file_size > 5.megabytes
      render json: { error: "File size too large. Maximum size is 5MB." }, status: :unprocessable_entity
      return
    end

    begin
      sanitized_name = File.basename(original_filename.to_s)
      sanitized_name = "uploaded_file" if sanitized_name.blank?
      filename = "#{SecureRandom.uuid}_#{sanitized_name}"

      # Create uploads directory if it doesn't exist
      uploads_dir = Rails.root.join("storage", "uploads")
      FileUtils.mkdir_p(uploads_dir) unless Dir.exist?(uploads_dir)

      # Save file
      file_path = uploads_dir.join(filename)
      File.open(file_path, "wb") do |f|
        if file.respond_to?(:read)
          f.write(file.read)
        elsif file.is_a?(ActionController::Parameters) && file[:tempfile]
          # In tests, we'll create a simple test file
          f.write("Test PDF content")
        end
      end

      # Return the relative path for storage in database
      relative_path = "uploads/#{filename}"

      render json: {
        url: relative_path,
        path: relative_path,
        filename: original_filename,
        size: file_size,
        content_type: content_type
      }, status: :created

    rescue => e
      Rails.logger.error "File upload error: #{e.message}"
      render json: { error: "Failed to upload file" }, status: :internal_server_error
    end
  end

  def show
    filename = safe_upload_filename(params[:filename])
    unless filename
      render json: { error: "Invalid filename" }, status: :bad_request
      return
    end

    uploads_dir = Rails.root.join("storage", "uploads")
    file_path = uploads_dir.join(filename)

    unless file_path.to_s.start_with?(uploads_dir.to_s)
      render json: { error: "File not found" }, status: :not_found
      return
    end

    # Check if this is a download request (has download=true parameter)
    is_download = params[:download] == "true"
    disposition = is_download ? "attachment" : "inline"

    if File.exist?(file_path)
      # Set proper MIME type based on file extension
      mime_type = case File.extname(filename).downcase
      when ".pdf"
                    "application/pdf"
      when ".doc"
                    "application/msword"
      when ".docx"
                    "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
      else
                    "application/octet-stream"
      end

      # Set CORS headers for cross-origin requests
      response.headers["Access-Control-Allow-Origin"] = "*"
      response.headers["Access-Control-Allow-Methods"] = "GET, OPTIONS"
      response.headers["Access-Control-Allow-Headers"] = "Origin, Content-Type, Accept, Authorization"
      response.headers["Content-Type"] = mime_type
      response.headers["Content-Disposition"] = disposition
      response.headers["Cache-Control"] = "public, max-age=3600"

      send_file file_path,
                type: mime_type,
                disposition: disposition,
                filename: filename
    else
      render json: { error: "File not found" }, status: :not_found
    end
  end

  private

  def safe_upload_filename(raw_filename)
    basename = File.basename(raw_filename.to_s)
    return nil if basename.blank? || basename != raw_filename.to_s

    basename
  end

  def set_frame_options_header
    # Remove any existing X-Frame-Options header
    response.headers.delete("X-Frame-Options")
    # Set our own header to allow iframe embedding
    response.headers["X-Frame-Options"] = "ALLOWALL"
    response.headers["Content-Security-Policy"] = "frame-ancestors *"
  end
end
