class CreateHelpdeskTickets < ActiveRecord::Migration[8.1]
  def change
    create_table :helpdesk_tickets do |t|
      t.string :title, null: false
      t.text :description
      t.string :category
      t.string :priority, default: "medium"
      t.string :status, default: "open"
      t.integer :assigned_to_id
      t.integer :requester_id
      t.integer :sla_hours
      t.string :sla_status, default: "on-track"
      t.string :channel, default: "portal"
      t.text :tags

      t.timestamps
    end

    add_index :helpdesk_tickets, :assigned_to_id
    add_index :helpdesk_tickets, :requester_id
    add_index :helpdesk_tickets, :status
    add_index :helpdesk_tickets, :category
    add_index :helpdesk_tickets, :priority
  end
end
