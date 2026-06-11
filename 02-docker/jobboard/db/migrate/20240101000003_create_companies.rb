class CreateCompanies < ActiveRecord::Migration[7.1]
  def change
    create_table :companies do |t|
      t.references :user,     null: false, foreign_key: true
      t.string     :name,     null: false
      t.string     :location, null: false
      t.string     :website
      t.text       :description
      t.timestamps
    end
  end
end
