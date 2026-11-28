class CreateHawkerDomain < ActiveRecord::Migration[8.1]
  def change
    create_table :hawker_profiles do |t|
      t.string :name
      t.string :availability, null: false, default: "offline"
      t.boolean :broadcasting, null: false, default: false
      t.timestamps
    end

    create_table :customers do |t|
      t.string :name, null: false
      t.string :phone
      t.timestamps
    end
    add_index :customers, :phone, unique: true, where: "phone IS NOT NULL"

    create_table :stops do |t|
      t.references :customer, null: false, foreign_key: true
      t.text :address, null: false
      t.text :items
      t.string :status, null: false, default: "requested"
      t.integer :sequence
      t.datetime :accepted_at
      t.datetime :arrived_at
      t.timestamps
    end
    add_index :stops, :status
    add_index :stops, %i[status sequence]
  end
end
