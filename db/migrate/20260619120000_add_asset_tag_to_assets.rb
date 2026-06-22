class AddAssetTagToAssets < ActiveRecord::Migration[8.1]
  def up
    add_column :assets, :asset_tag, :string
    add_index :assets, :asset_tag, unique: true

    say_with_time "Backfilling asset tags" do
      Asset.reset_column_information
      Asset.find_each do |asset|
        next if asset.asset_tag.present?

        asset.update_column(:asset_tag, generate_asset_tag(asset))
      end
    end

    change_column_null :assets, :asset_tag, false
  end

  def down
    remove_index :assets, :asset_tag
    remove_column :assets, :asset_tag
  end

  private

  def generate_asset_tag(asset)
    loop do
      tag = format("AST-%s-%s", asset.company_id, SecureRandom.alphanumeric(8).upcase)
      break tag unless Asset.exists?(asset_tag: tag)
    end
  end
end
