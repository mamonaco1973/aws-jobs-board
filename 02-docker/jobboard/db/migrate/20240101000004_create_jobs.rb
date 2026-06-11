class CreateJobs < ActiveRecord::Migration[7.1]
  def change
    create_table :jobs do |t|
      t.references :company,    null: false, foreign_key: true
      t.string     :title,      null: false
      t.text       :description, null: false
      t.string     :location,   null: false
      t.string     :job_type
      t.integer    :salary_min
      t.integer    :salary_max
      t.timestamps
    end

    add_index :jobs, :created_at
  end
end
