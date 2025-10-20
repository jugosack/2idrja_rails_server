class CreatePayments < ActiveRecord::Migration[7.0]
  def change
    create_table :payments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true
      t.integer :amount, null: false
      t.string :currency, default: 'usd'
      t.string :stripe_payment_intent_id, null: false
      t.string :status, default: 'pending'

      t.timestamps
    end
    add_index :payments, :stripe_payment_intent_id, unique: true
  end
end
