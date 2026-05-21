class CreateSpecimens < ActiveRecord::Migration[8.1]
  def change
    create_table :specimens do |t|
      t.string :name, null: false
      t.string :color
      t.decimal :mohs, precision: 4, scale: 1
      t.string :origin
      t.text :fact
      t.string :tint, default: "slate"

      t.timestamps
    end

    add_index :specimens, :name
  end
end
