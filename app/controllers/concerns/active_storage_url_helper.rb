# frozen_string_literal: true

module ActiveStorageUrlHelper
  extend ActiveSupport::Concern

  def active_storage_blob_url(attachment)
    BlobUrl.for(attachment)
  end
end
