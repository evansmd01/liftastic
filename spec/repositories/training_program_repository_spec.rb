require 'rails_helper'

describe TrainingProgramRepository do
  it "inserts a record" do
    repo = subject
    program = build(:training_program)

    expect(program.id).to eq(nil)
    repo.insert(program)
    expect(program.id).to_not eq(nil)

    reloaded = repo.get(program.id)

    expect(reloaded.deep_attributes).to eq(program.deep_attributes)
  end
end