class CreateKnowledgeArticles < ActiveRecord::Migration[8.1]
  def change
    create_table :knowledge_articles do |t|
      t.string :title, null: false
      t.text :content
      t.string :category
      t.string :author
      t.text :tags
      t.integer :views, default: 0
      t.integer :helpful, default: 0
      t.string :status, default: "draft"
      t.datetime :last_updated

      t.timestamps
    end

    add_index :knowledge_articles, :category
    add_index :knowledge_articles, :status
  end
end
