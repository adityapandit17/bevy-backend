class CreateErrorTrackTables < ActiveRecord::Migration[8.1]
  def change
    create_table :error_track_error_events do |t|
      t.string   :fingerprint, null: false
      t.string   :klass, null: false
      t.text     :message
      t.integer  :occurrences_count, null: false, default: 0
      t.boolean  :resolved, null: false, default: false
      t.datetime :first_seen_at
      t.datetime :last_seen_at

      t.timestamps
    end
    add_index :error_track_error_events, :fingerprint, unique: true
    add_index :error_track_error_events, :last_seen_at
    add_index :error_track_error_events, :resolved

    create_table :error_track_occurrences do |t|
      t.references :error_event, null: false, foreign_key: { to_table: :error_track_error_events }
      t.text     :backtrace
      t.json     :context
      t.string   :environment
      t.datetime :occurred_at

      t.timestamps
    end
    add_index :error_track_occurrences, :occurred_at
  end
end
