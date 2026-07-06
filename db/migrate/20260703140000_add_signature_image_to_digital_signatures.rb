# frozen_string_literal: true

class AddSignatureImageToDigitalSignatures < ActiveRecord::Migration[8.1]
  def change
    add_column :digital_signatures, :signature_image, :text
  end
end
