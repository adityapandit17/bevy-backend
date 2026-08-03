# frozen_string_literal: true

# Offline-safe avatar placeholders (no external HTTP like ui-avatars.com).
module LocalAvatar
  COLORS = %w[#16a34a #2563eb #7c3aed #db2777 #ea580c #0891b2 #4f46e5 #0d9488].freeze

  module_function

  def url_for(name)
    label = initials_for(name)
    color = COLORS[name.to_s.hash.abs % COLORS.length]
    svg = +<<~SVG
      <svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">
        <rect width="128" height="128" fill="#{color}"/>
        <text x="64" y="64" dy=".35em" text-anchor="middle" fill="#ffffff"
          font-family="system-ui,-apple-system,sans-serif" font-size="48" font-weight="600">#{ERB::Util.html_escape(label)}</text>
      </svg>
    SVG

    "data:image/svg+xml;base64,#{Base64.strict_encode64(svg)}"
  end

  def initials_for(name)
    parts = name.to_s.split(/\s+/).reject(&:blank?)
    label = parts.first(2).map { |part| part[0] }.join.upcase
    label.presence || "?"
  end
end
