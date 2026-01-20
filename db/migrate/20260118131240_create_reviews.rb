class CreateReviews < ActiveRecord::Migration[7.0]
  def change
    create_table :reviews do |t|
      t.references :user, null: false, foreign_key: true
      t.references :course, null: false, foreign_key: true
      t.string :title
      t.text :body, null: false
      t.integer :rating, null: false
      t.jsonb :flags, default: {}

      t.timestamps
    end

    add_index :reviews, :flags, using: :gin
  end
end
