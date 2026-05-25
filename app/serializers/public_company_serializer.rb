# frozen_string_literal: true

class PublicCompanySerializer < Panko::Serializer
  attributes :name, :careers_slug, :logo_url

  def logo_url
    object.logo_url
  end
end
