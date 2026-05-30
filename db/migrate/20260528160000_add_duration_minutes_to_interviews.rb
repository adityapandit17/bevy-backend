# frozen_string_literal: true

class AddDurationMinutesToInterviews < ActiveRecord::Migration[8.1]
  def change
    add_column :interviews, :duration_minutes, :integer, default: 60, null: false
  end
end
