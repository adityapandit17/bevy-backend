class AddDetailsToPayrolls < ActiveRecord::Migration[8.0]
  def change
    change_table :payrolls, bulk: true do |t|
      t.integer :working_days
      t.decimal :payable_days, precision: 10, scale: 2
      t.decimal :unpaid_days, precision: 10, scale: 2
      t.decimal :leave_deduction, precision: 12, scale: 2
      t.json :earnings_breakdown, default: {}
      t.json :deductions_breakdown, default: {}
      t.string :run_mode
      t.datetime :processed_at
    end
  end
end
