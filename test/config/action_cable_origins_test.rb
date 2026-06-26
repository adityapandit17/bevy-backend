# frozen_string_literal: true

require "test_helper"

class ActionCableOriginsTest < ActiveSupport::TestCase
  test "production origin patterns match full https URLs from env" do
    patterns = build_origin_patterns(%w[https://bevyhr.com https://www.bevyhr.com])

    assert patterns.any? { |rx| rx.match?("https://bevyhr.com") }
    assert patterns.any? { |rx| rx.match?("https://www.bevyhr.com") }
    refute patterns.any? { |rx| rx.match?("https://evil.com") }
  end

  test "production origin patterns match host-only env values" do
    patterns = build_origin_patterns(%w[bevyhr.com www.bevyhr.com])

    assert patterns.any? { |rx| rx.match?("https://bevyhr.com") }
    assert patterns.any? { |rx| rx.match?("http://www.bevyhr.com") }
  end

  private

  def build_origin_patterns(origins)
    origins.map do |origin|
      if origin.match?(%r{\Ahttps?://}i)
        Regexp.new("^#{Regexp.escape(origin).gsub('\*', '.*')}$")
      else
        escaped = origin.gsub(".", "\\.").gsub("*", ".*")
        Regexp.new("^https?://#{escaped}$")
      end
    end
  end
end
