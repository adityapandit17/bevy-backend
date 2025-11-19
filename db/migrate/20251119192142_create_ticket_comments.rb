class CreateTicketComments < ActiveRecord::Migration[8.1]
  def change
    create_table :ticket_comments do |t|
      t.integer :helpdesk_ticket_id, null: false
      t.integer :user_id
      t.integer :employee_id
      t.text :content, null: false

      t.timestamps
    end

    add_index :ticket_comments, :helpdesk_ticket_id
    add_index :ticket_comments, :user_id
    add_index :ticket_comments, :employee_id
    add_index :ticket_comments, :created_at
  end
end
