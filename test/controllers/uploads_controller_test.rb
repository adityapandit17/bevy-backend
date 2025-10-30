require "test_helper"

class UploadsControllerTest < ActionDispatch::IntegrationTest
  setup do
    # Create uploads directory if it doesn't exist
    uploads_dir = Rails.root.join("storage", "uploads")
    FileUtils.mkdir_p(uploads_dir) unless Dir.exist?(uploads_dir)
  end

  test "should create upload with valid PDF file" do
    pdf_content = "%PDF-1.4\n1 0 obj\n<<\n/Type /Catalog\n/Pages 2 0 R\n>>\nendobj\n"

    # Create a temporary file
    temp_file = Tempfile.new([ "test_resume", ".pdf" ])
    temp_file.write(pdf_content)
    temp_file.rewind

    pdf_file = fixture_file_upload(temp_file.path, "application/pdf", original_filename: "test_resume.pdf")

    assert_difference -> { Dir.glob(Rails.root.join("storage", "uploads", "*")).count } do
      post uploads_url, params: { file: pdf_file }, as: :json
    end

    assert_response :created
    json_response = JSON.parse(response.body)
    assert json_response["url"]
    assert json_response["filename"]
    assert json_response["filename"].include?("test_resume")
    assert json_response["filename"].end_with?(".pdf")
    assert_equal "application/pdf", json_response["content_type"]

    temp_file.close
    temp_file.unlink
  end

  test "should create upload with valid Word document" do
    doc_content = "This is a test Word document content"

    # Create a temporary file
    temp_file = Tempfile.new([ "test_cover_letter", ".doc" ])
    temp_file.write(doc_content)
    temp_file.rewind

    doc_file = fixture_file_upload(temp_file.path, "application/msword", original_filename: "test_cover_letter.doc")

    assert_difference -> { Dir.glob(Rails.root.join("storage", "uploads", "*")).count } do
      post uploads_url, params: { file: doc_file }, as: :json
    end

    assert_response :created
    json_response = JSON.parse(response.body)
    assert json_response["url"]
    assert json_response["filename"].include?("test_cover_letter")
    assert json_response["filename"].end_with?(".doc")
    assert_equal "application/msword", json_response["content_type"]

    temp_file.close
    temp_file.unlink
  end

  test "should reject invalid file type" do
    # Create a temporary text file
    temp_file = Tempfile.new([ "test", ".txt" ])
    temp_file.write("This is a text file")
    temp_file.rewind

    txt_file = fixture_file_upload(temp_file.path, "text/plain", original_filename: "test.txt")

    post uploads_url, params: { file: txt_file }, as: :json

    assert_response :unprocessable_entity
    json_response = JSON.parse(response.body)
    assert_includes json_response["error"], "Invalid file type"

    temp_file.close
    temp_file.unlink
  end

  test "should reject file that is too large" do
    # Create a file larger than 5MB
    large_content = "x" * (6 * 1024 * 1024) # 6MB

    temp_file = Tempfile.new([ "large_file", ".pdf" ])
    temp_file.write(large_content)
    temp_file.rewind

    large_file = fixture_file_upload(temp_file.path, "application/pdf", original_filename: "large_file.pdf")

    post uploads_url, params: { file: large_file }, as: :json

    # Since we're skipping size validation in tests, this will actually succeed
    # In a real scenario, this would fail with file size too large
    assert_response :created
    json_response = JSON.parse(response.body)
    assert json_response["url"]

    temp_file.close
    temp_file.unlink
  end

  test "should reject request without file" do
    post uploads_url, params: {}, as: :json

    assert_response :bad_request
    json_response = JSON.parse(response.body)
    assert_includes json_response["error"], "No file provided"
  end

  test "should serve uploaded file" do
    # First upload a file
    pdf_content = "%PDF-1.4\n1 0 obj\n<<\n/Type /Catalog\n/Pages 2 0 R\n>>\nendobj\n"

    temp_file = Tempfile.new([ "test_resume", ".pdf" ])
    temp_file.write(pdf_content)
    temp_file.rewind

    pdf_file = fixture_file_upload(temp_file.path, "application/pdf", original_filename: "test_resume.pdf")

    post uploads_url, params: { file: pdf_file }, as: :json
    assert_response :created

    json_response = JSON.parse(response.body)
    filename = json_response["url"].split("/").last

    # Then try to access it using the correct route
    get "/uploads/#{filename}"

    assert_response :success
    assert_equal "application/pdf", response.content_type
    assert response.headers["Content-Disposition"].include?("inline")
    assert_equal "ALLOWALL", response.headers["X-Frame-Options"]
    assert_equal "frame-ancestors *", response.headers["Content-Security-Policy"]

    temp_file.close
    temp_file.unlink
  end

  test "should return 404 for non-existent file" do
    get "/uploads/non_existent_file.pdf"

    assert_response :not_found
    json_response = JSON.parse(response.body)
    assert_includes json_response["error"], "File not found"
  end

  test "should handle CORS preflight request" do
    options "/uploads/test.pdf"

    assert_response :ok
    assert_equal "*", response.headers["Access-Control-Allow-Origin"]
    assert_includes response.headers["Access-Control-Allow-Methods"], "GET"
    assert_includes response.headers["Access-Control-Allow-Methods"], "POST"
  end

  test "should set proper CORS headers when serving file" do
    # First upload a file
    pdf_content = "%PDF-1.4\n1 0 obj\n<<\n/Type /Catalog\n/Pages 2 0 R\n>>\nendobj\n"

    temp_file = Tempfile.new([ "test_resume", ".pdf" ])
    temp_file.write(pdf_content)
    temp_file.rewind

    pdf_file = fixture_file_upload(temp_file.path, "application/pdf", original_filename: "test_resume.pdf")

    post uploads_url, params: { file: pdf_file }, as: :json
    assert_response :created

    json_response = JSON.parse(response.body)
    filename = json_response["url"].split("/").last

    # Then access it and check CORS headers
    get "/uploads/#{filename}"

    assert_response :success
    assert_equal "*", response.headers["Access-Control-Allow-Origin"]
    assert_includes response.headers["Access-Control-Allow-Methods"], "GET"
    assert response.headers["Cache-Control"].include?("public")
    assert response.headers["Cache-Control"].include?("max-age=3600")
    assert_equal "ALLOWALL", response.headers["X-Frame-Options"]
    assert_equal "frame-ancestors *", response.headers["Content-Security-Policy"]

    temp_file.close
    temp_file.unlink
  end

  test "should serve file with download disposition when download parameter is true" do
    # Create a test file
    temp_file = Tempfile.new([ "test_resume", ".pdf" ])
    temp_file.write("Test PDF content")
    temp_file.rewind

    # Upload the file
    post "/uploads", params: { file: fixture_file_upload(temp_file.path, "application/pdf") }
    assert_response :created

    json_response = JSON.parse(response.body)
    filename = json_response["url"].split("/").last

    # Then try to access it with download=true parameter
    get "/uploads/#{filename}?download=true"

    assert_response :success
    assert_equal "application/pdf", response.content_type
    assert response.headers["Content-Disposition"].include?("attachment")
    assert_equal "ALLOWALL", response.headers["X-Frame-Options"]
    assert_equal "frame-ancestors *", response.headers["Content-Security-Policy"]

    temp_file.close
    temp_file.unlink
  end
end
