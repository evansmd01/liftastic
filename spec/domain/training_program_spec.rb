require 'spec_helper'
require_relative '../../app/domain/entities/training_program'

describe Domain::Entities::TrainingProgram do

  context "with no user history" do

    it "calculates exercise prescriptions for week 1 day 1" do
      expect(true).to eq(false)
    end

    it "outputs intensity descriptions if working max is 0" do
      expect(true).to eq(false)
    end

  end

end
