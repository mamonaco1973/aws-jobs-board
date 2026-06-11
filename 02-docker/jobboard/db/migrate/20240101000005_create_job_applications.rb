class CreateJobApplications < ActiveRecord::Migration[7.1]
  def change
    create_table :job_applications do |t|
      t.references :user, null: false, foreign_key: true
      t.references :job,  null: false, foreign_key: true
      t.text    :cover_letter, null: false
      t.integer :status,       null: false, default: 0
      t.timestamps
    end

    # Prevent duplicate applications from same candidate to same job
    add_index :job_applications, [:user_id, :job_id], unique: true
  end
end
