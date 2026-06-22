# frozen_string_literal: true

require "rqrcode"
require "barby"
require "barby/barcode/code_128"
require "barby/outputter/png_outputter"

class AssetLabelService
  SCAN_PREFIX = "BEVYHR|AST|"

  def initialize(asset)
    @asset = asset
  end

  def scan_payload
    "#{SCAN_PREFIX}#{@asset.asset_tag}"
  end

  def qr_png
    RQRCode::QRCode.new(scan_payload).as_png(
      bit_depth: 1,
      border_modules: 2,
      color_mode: ChunkyPNG::COLOR_GRAYSCALE,
      color: "black",
      fill: "white",
      module_px_size: 6,
      size: 240
    ).to_s
  end

  def barcode_png
    barcode = Barby::Code128B.new(scan_payload)
    Barby::PngOutputter.new(barcode).to_png(margin: 10, xdim: 2, height: 72)
  end

  def label_metadata(base_url:)
    base = base_url.to_s.chomp("/")
    {
      asset_id: @asset.id,
      asset_tag: @asset.asset_tag,
      scan_payload: scan_payload,
      serial_number: @asset.serial_number,
      name: @asset.name,
      brand: @asset.brand,
      model: @asset.model,
      qr_code_url: "#{base}/api/assets/#{@asset.id}/qr_code",
      barcode_url: "#{base}/api/assets/#{@asset.id}/barcode"
    }
  end
end
