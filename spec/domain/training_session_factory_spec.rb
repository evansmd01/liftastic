require 'spec_helper'
require_relative '../../app/domain/services/training_session_factory'
require_relative '../../app/domain/entities/prescription_identifier'

services = Domain::Services

describe services::TrainingSessionFactory do

  let(:user_id) { "1" }
  let(:program_repo) { double("StubProgramRepository") }
  let(:history_repo) { double("StubProgramRepository") }
  let(:working_max_repo) { double("StubProgramRepository") }
  let(:exercise_repo) { double("StubProgramRepository") }
  let(:factory) { services::TrainingSessionFactory.new(program_repo, history_repo, working_max_repo, exercise_repo)}

  context "with a single training day per week and a single exercise" do
    let(:day_index) { 0 }
    let(:exercise) { build(:exercise, name: "squats")}
    let(:program) {
      build(:training_program, days: [
        build(:training_day, description: "leg day", groups: [
            build(:prescription_group, exercises: [
                build(:exercise_prescription, exercise_id: exercise.id, weeks: [
                    build(:week_prescription, description: "week 1", sets: [
                        build(:set_prescription, reps: 3, intensity: 90),
                        build(:set_prescription, reps: 5, intensity: 80)
                    ])])])])])
    }

    before :each do
      allow(program_repo).to receive(:get).with(program.id).and_return(program)
      allow(exercise_repo).to receive(:get).with(exercise.id).and_return(exercise)
      allow(working_max_repo).to receive(:get).with(user_id, exercise.id).and_return(200)
    end

    it "calculates exercise prescriptions for week 1 day 1" do
      week_index = 0
      session = factory.generate_training_session(user_id, program.id, day_index, week_index)

      expect(session.description).to eq("leg day")
      expect(session.groups.count).to eq(1)
      expect(session.groups.first.exercises.count).to eq(1)
      expect(session.groups.first.exercises.first.exercise.name).to eq("squats")
      expect(session.groups.first.exercises.first.sets.count).to eq(2)
      expect(session.groups.first.exercises.first.sets[0].reps).to eq(3)
      expect(session.groups.first.exercises.first.sets[0].weight).to eq(180)
      expect(session.groups.first.exercises.first.sets[1].reps).to eq(5)
      expect(session.groups.first.exercises.first.sets[1].weight).to eq(160)
    end

    context "during week 2" do
      let(:week_index) { 1 }
      context "when not building upon a previouse week" do
        it "uses week 2 prescription" do
          weeks = program.days[0].groups[0].exercises[0].weeks
          weeks << build(:week_prescription, description: "week 2", sets: [
              build(:set_prescription, reps: 3, intensity: 95),
              build(:set_prescription, reps: 5, intensity: 85),
          ])

          session = factory.generate_training_session(user_id, program.id, day_index, week_index)

          expect(session.groups.first.exercises.first.description).to eq("week 2")
          expect(session.groups.first.exercises.first.sets.count).to eq(2)
          expect(session.groups.first.exercises.first.sets[0].reps).to eq(3)
          expect(session.groups.first.exercises.first.sets[0].weight).to eq(190)
          expect(session.groups.first.exercises.first.sets[1].reps).to eq(5)
          expect(session.groups.first.exercises.first.sets[1].weight).to eq(170)
        end
      end

      context "when building upon previous week" do
        it "falls back to week 1 if no history is recorded for week 1" do
          weeks = program.days[0].groups[0].exercises[0].weeks
          weeks << build(:week_prescription, description: "week 2", build_on_week: 0, sets: [
              build(:set_prescription, reps: 3, intensity: 95),
              build(:set_prescription, reps: 5, intensity: 85),
          ])
          allow(history_repo).to receive(:get).and_return(nil)

          session = factory.generate_training_session(user_id, program.id, day_index, week_index)

          expect(session.groups.first.exercises.first.description).to eq("week 1")
          expect(session.groups.first.exercises.first.sets.count).to eq(2)
          expect(session.groups.first.exercises.first.sets[0].reps).to eq(3)
          expect(session.groups.first.exercises.first.sets[0].weight).to eq(180)
          expect(session.groups.first.exercises.first.sets[1].reps).to eq(5)
          expect(session.groups.first.exercises.first.sets[1].weight).to eq(160)
        end

        it "falls back to week 1 if history is recorded, but was not completed as prescribed" do
          weeks = program.days[0].groups[0].exercises[0].weeks
          weeks << build(:week_prescription, description: "week 2", build_on_week: 0, sets: [
              build(:set_prescription, reps: 3, intensity: 95),
              build(:set_prescription, reps: 5, intensity: 85),
          ])
          rx_id = Domain::Entities::PrescriptionIdentifier.new(program_id: program.id,
                        day_index: day_index,
                        group_index: 0,
                        exercise_index: 0,
                        week_index: week_index)
          history = build(:training_history, completed_as_prescribed: false)

          allow(history_repo).to receive(:get).with(user_id, rx_id).and_return(history)

          session = factory.generate_training_session(user_id, program.id, day_index, week_index)

          expect(session.groups.first.exercises.first.description).to eq("week 1")
          expect(session.groups.first.exercises.first.sets.count).to eq(2)
          expect(session.groups.first.exercises.first.sets[0].reps).to eq(3)
          expect(session.groups.first.exercises.first.sets[0].weight).to eq(180)
          expect(session.groups.first.exercises.first.sets[1].reps).to eq(5)
          expect(session.groups.first.exercises.first.sets[1].weight).to eq(160)
        end
      end
    end
  end
end
