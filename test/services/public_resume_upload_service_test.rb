# frozen_string_literal: true

require "test_helper"

class PublicResumeUploadServiceTest < ActiveSupport::TestCase
  test "stores valid pdf file" do
    file = Rack::Test::UploadedFile.new(
      Rails.root.join("test/fixtures/files/sample_resume.pdf"),
      "application/pdf",
      original_filename: "applicant.pdf"
    )

    path = PublicResumeUploadService.store!(file)
    assert path.start_with?("uploads/resume_")
    assert path.end_with?(".pdf")
    assert File.exist?(Rails.root.join("storage", path))
  end

  test "rejects invalid extension" do
    file = Rack::Test::UploadedFile.new(
      StringIO.new("not a resume"),
      "text/plain",
      original_filename: "resume.txt"
    )

    assert_raises(PublicResumeUploadService::Error) do
      PublicResumeUploadService.store!(file)
    end
  end
end
