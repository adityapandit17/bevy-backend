# frozen_string_literal: true

class AddAppraisalFieldsToSalaryStructures < ActiveRecord::Migration[8.1]
  def change
    add_column :salary_structures, :revision_type, :string, default: "appraisal", null: false
    add_column :salary_structures, :notes, :text
    add_column :salary_structures, :previous_annual_ctc, :decimal, precision: 12, scale: 2
    add_column :salary_structures, :created_by_id, :bigint

    add_index :salary_structures, :revision_type
    add_index :salary_structures, :created_by_id
    add_index :salary_structures, [ :employee_id, :effective_from ], name: "index_salary_structures_on_employee_and_effective_from"
  end
end
