# frozen_string_literal: true

class BlobUrl
  include Rails.application.routes.url_helpers

  def self.for(attachment)
    return nil unless attachment&.attached?

    app_url = ENV.fetch("APP_URL", "http://localhost:3000")
    uri = URI.parse(app_url)
    options = {
      host: uri.host,
      protocol: uri.scheme || "http"
    }
    options[:port] = uri.port if uri.port && ![ 80, 443 ].include?(uri.port)

    new.rails_blob_url(attachment, **options)
  end
end
