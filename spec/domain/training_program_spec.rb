require 'spec_helper'
require_relative '../../app/domain/entities/training_program'


describe Domain::Entities::TrainingProgram do

  let(:program) {
    Domain::Entities::TrainingProgram.new(id: "1", days: [
        {
            description: "Max Effort",
            prescriptions: [
                {
                    exercises: [
                        {
                            exercise_id: "1",
                            weeks: [
                                {
                                    build_on_week: nil,
                                    sets: [
                                        {
                                            reps: 1,
                                            intensity: { percent: 90 }
                                        },
                                        {
                                            reps: 3,
                                            intensity: { percent: 80 }
                                        },
                                        {
                                            reps: 3,
                                            intensity: { percent: 80 }
                                        }
                                    ]
                                },
                                {
                                    build_on_week: 1,
                                    description: "increases week 1 by 5%",
                                    sets: [
                                        {
                                            reps: 1,
                                            intensity: { increase: 5 }
                                        },
                                        {
                                            reps: 3,
                                            intensity: { increase: 5 }
                                        },
                                        {
                                            reps: 3,
                                            intensity: { increase: 5 }
                                        }
                                    ]
                                },
                                {
                                    build_on_week: nil,
                                    description: "deload week, using lighter weights",
                                    sets: [
                                        {
                                            reps: 1,
                                            intensity: { percent: 80 }
                                        },
                                        {
                                            reps: 3,
                                            intensity: { percent: 70 }
                                        },
                                        {
                                            reps: 3,
                                            intensity: { percent: 70 }
                                        }
                                    ]
                                },
                                {
                                    build_on_week: 2,
                                    description: "increases week 2 by 5%",
                                    sets: [
                                        {
                                            reps: 1,
                                            intensity: { increase: 5 }
                                        },
                                        {
                                            reps: 3,
                                            intensity: { increase: 5 }
                                        },
                                        {
                                            reps: 3,
                                            intensity: { increase: 5 }
                                        }
                                    ]
                                }
                            ]
                        }
                    ]
                }
            ]
        }
    ])
  }

  context "with no user history" do

    it "calculates exercise prescriptions for week 1 day 1" do



      expect(true).to eq(false)
    end

    it "outputs intensity descriptions if working max is 0" do
      expect(true).to eq(false)
    end

  end

end
