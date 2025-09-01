class AddDriverToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :driver, :boolean
  end
end
