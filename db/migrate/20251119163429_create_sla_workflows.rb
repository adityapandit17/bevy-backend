class CreateSlaWorkflows < ActiveRecord::Migration[8.1]
  def change
    create_table :sla_workflows do |t|
      t.string :name, null: false
      t.string :category
      t.string :priority, default: "medium"
      t.integer :sla_hours, null: false
      t.string :status, default: "active"
      t.integer :tickets_handled, default: 0
      t.decimal :avg_resolution_hours, precision: 10, scale: 2
      t.text :escalation_levels

      t.timestamps
    end

    add_index :sla_workflows, :category
    add_index :sla_workflows, :status
  end
end
