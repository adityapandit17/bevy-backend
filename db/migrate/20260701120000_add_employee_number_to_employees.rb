# frozen_string_literal: true

class AddEmployeeNumberToEmployees < ActiveRecord::Migration[8.1]
  def up
    add_column :employees, :employee_number, :integer

    execute(<<-SQL.squish)
      WITH numbered AS (
        SELECT id,
               ROW_NUMBER() OVER (PARTITION BY company_id ORDER BY id ASC) AS num
        FROM employees
      )
      UPDATE employees
      SET employee_number = numbered.num
      FROM numbered
      WHERE employees.id = numbered.id
    SQL

    change_column_null :employees, :employee_number, false
    add_index :employees, %i[company_id employee_number], unique: true
  end

  def down
    remove_index :employees, column: %i[company_id employee_number]
    remove_column :employees, :employee_number
  end
end
