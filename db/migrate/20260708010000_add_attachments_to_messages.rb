# frozen_string_literal: true

class AddAttachmentsToMessages < ActiveRecord::Migration[8.1]
  def change
    change_column_null :messages, :content, true

    add_column :messages, :attachment_path, :string
    add_column :messages, :attachment_filename, :string
    add_column :messages, :attachment_content_type, :string
  end
end
