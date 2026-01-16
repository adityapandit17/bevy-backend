class CreateHuddleParticipants < ActiveRecord::Migration[8.1]
  def change
    create_table :huddle_participants do |t|
      t.references :huddle, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: { to_table: :users }
      t.datetime :joined_at
      t.datetime :left_at

      t.timestamps
    end

    add_index :huddle_participants, [:huddle_id, :user_id], unique: true
  end
end
