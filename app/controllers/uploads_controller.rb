class UploadsController < ApplicationController
  def create
    if params[:file].blank?
      render json: { error: "No file provided" }, status: :bad_request
      return
    end

    file = params[:file]
    
    # Validate file type
    allowed_types = ['application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document']
    unless allowed_types.include?(file.content_type)
      render json: { error: "Invalid file type. Only PDF and Word documents are allowed." }, status: :unprocessable_entity
      return
    end

    # Validate file size (5MB limit)
    if file.size > 5.megabytes
      render json: { error: "File size too large. Maximum size is 5MB." }, status: :unprocessable_entity
      return
    end

    begin
      # Generate unique filename
      filename = "#{SecureRandom.uuid}_#{file.original_filename}"
      
      # Create uploads directory if it doesn't exist
      uploads_dir = Rails.root.join('storage', 'uploads')
      FileUtils.mkdir_p(uploads_dir) unless Dir.exist?(uploads_dir)
      
      # Save file
      file_path = uploads_dir.join(filename)
      File.open(file_path, 'wb') do |f|
        f.write(file.read)
      end

      # Return the relative path for storage in database
      relative_path = "uploads/#{filename}"
      
      render json: { 
        url: relative_path,
        path: relative_path,
        filename: file.original_filename,
        size: file.size,
        content_type: file.content_type
      }, status: :created
      
    rescue => e
      Rails.logger.error "File upload error: #{e.message}"
      render json: { error: "Failed to upload file" }, status: :internal_server_error
    end
  end

  def show
    filename = params[:filename]
    file_path = Rails.root.join('storage', 'uploads', filename)
    
    if File.exist?(file_path)
      send_file file_path, disposition: 'inline'
    else
      render json: { error: "File not found" }, status: :not_found
    end
  end
end
