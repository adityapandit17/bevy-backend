require "test_helper"

class AssetLabelServiceTest < ActiveSupport::TestCase
  def setup
    @asset = assets(:one)
  end

  test "scan_payload uses asset tag prefix" do
    service = AssetLabelService.new(@asset)
    assert_equal "BEVYHR|AST|#{@asset.asset_tag}", service.scan_payload
  end

  test "generates qr png bytes" do
    png = AssetLabelService.new(@asset).qr_png
    assert png.start_with?("\x89PNG".b)
  end

  test "generates barcode png bytes" do
    png = AssetLabelService.new(@asset).barcode_png
    assert png.start_with?("\x89PNG".b)
  end
end
