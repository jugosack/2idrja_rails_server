class AddDetailsToUsers < ActiveRecord::Migration[7.0]
  def change
    # rubocop:disable Rails/BulkChangeTable, Rails/ThreeStateBooleanColumn
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    add_column :users, :country, :string
    add_column :users, :mobile_number, :string
    add_column :users, :terms_of_use, :boolean
    # rubocop:enable Rails/BulkChangeTable, Rails/ThreeStateBooleanColumn
  end
end
