class CreateLikes < ActiveRecord::Migration[8.1]
  def change
    create_table :likes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :specimen, null: false, foreign_key: true

      t.timestamps
    end

    # One like per user per specimen.
    add_index :likes, %i[user_id specimen_id], unique: true
  end
end
