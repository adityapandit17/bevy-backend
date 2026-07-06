# frozen_string_literal: true

class CreateWorkspaceProjectsExpenses < ActiveRecord::Migration[8.1]
  def change
    create_table :workspace_seats do |t|
      t.references :company, null: false, foreign_key: true
      t.string :label, null: false
      t.string :zone, null: false, default: "center"
      t.string :status, null: false, default: "vacant"
      t.references :employee, foreign_key: true
      t.timestamps
    end
    add_index :workspace_seats, [ :company_id, :label ], unique: true

    create_table :projects do |t|
      t.references :company, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.string :status, null: false, default: "planning"
      t.integer :progress, null: false, default: 0
      t.string :priority, null: false, default: "medium"
      t.date :start_date
      t.date :end_date
      t.decimal :budget, precision: 12, scale: 2
      t.decimal :spent, precision: 12, scale: 2, default: 0
      t.timestamps
    end

    create_table :project_tasks do |t|
      t.references :company, null: false, foreign_key: true
      t.references :project, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.string :status, null: false, default: "backlog"
      t.string :priority, null: false, default: "medium"
      t.references :employee, foreign_key: true
      t.string :assignee_name
      t.date :due_date
      t.integer :story_points
      t.string :sprint_name
      t.jsonb :tags, default: []
      t.timestamps
    end
    add_index :project_tasks, [ :project_id, :status ]

    create_table :expenses do |t|
      t.references :company, null: false, foreign_key: true
      t.references :employee, null: false, foreign_key: true
      t.string :title, null: false
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.string :category, null: false
      t.date :expense_date, null: false
      t.text :description
      t.string :payment_method
      t.jsonb :tags, default: []
      t.string :receipt_url
      t.string :status, null: false, default: "submitted"
      t.timestamps
    end
    add_index :expenses, [ :company_id, :expense_date ]
  end
end
