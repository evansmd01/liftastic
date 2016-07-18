class CreateTrainingPrograms < ActiveRecord::Migration[5.0]
  def change
    create_table :training_programs do |t|
      t.string :name, null: false
      t.jsonb :days, null: false
      t.timestamps
    end
  end
end
