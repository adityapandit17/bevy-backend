class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.string :title, null: false
      t.text :description
      t.string :event_type, default: "meeting"
      t.datetime :start_time, null: false
      t.datetime :end_time, null: false
      t.string :location
      t.integer :organizer_id
      t.string :status, default: "scheduled"
      t.text :attendee_ids

      t.timestamps
    end

    add_index :events, :organizer_id
    add_index :events, :start_time
    add_index :events, :status
    add_index :events, :event_type
  end
end
