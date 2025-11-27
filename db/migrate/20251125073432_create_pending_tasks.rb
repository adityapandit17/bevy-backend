class CreatePendingTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :pending_tasks do |t|
      t.references :taskable, polymorphic: true, null: false, index: true
      t.references :assigned_to, null: true, foreign_key: { to_table: :employees }
      t.string :title, null: false
      t.string :priority, default: "medium"
      t.date :due_date
      t.string :status, default: "pending"

      t.timestamps
    end

    add_index :pending_tasks, [:taskable_type, :taskable_id]
    add_index :pending_tasks, :status
    add_index :pending_tasks, :due_date
    add_index :pending_tasks, [:assigned_to_id, :status]
  end
end
