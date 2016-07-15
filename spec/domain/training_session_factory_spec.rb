require 'spec_helper'
require_relative '../../app/domain/services/training_session_factory'
require_relative '../../app/domain/values/prescription_identifier'

services = Domain::Services

describe services::TrainingSessionFactory do

  let(:user_id) { "1" }
  let(:program_repo) { double("StubProgramRepository") }
  let(:history_repo) { double("StubHistoryRepository") }
  let(:working_max_repo) { double("StubWorkingMaxRepository") }
  let(:exercise_repo) { double("StubExerciseRepository") }
  let(:factory) { services::TrainingSessionFactory.new(program_repo, history_repo, working_max_repo, exercise_repo)}

  context "with a single training day per week" do
    let(:day_index) { 0 }
    let(:program) {
      build(:training_program, days: [
        build(:training_day, description: "leg day", groups: [])
      ])
    }

    context "with a single exercise" do
      before :each do
        squats = build(:exercise, name: "squats")
        program.days[day_index].groups << build(:prescription_group, exercises: [
            build(:exercise_prescription, exercise_id: squats.id, weeks: [
                build(:week_prescription, description: "week 1", sets: [
                    build(:set_prescription, reps: 3, intensity: 90),
                    build(:set_prescription, reps: 5, intensity: 80)
                ])])])
        allow(program_repo).to receive(:get).with(program.id).and_return(program)
        allow(exercise_repo).to receive(:get).with(squats.id).and_return(squats)
        allow(working_max_repo).to receive(:get).with(user_id, squats.id).and_return(200)
      end

      it "calculates training session for week 1 day 1" do
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
        context "when NOT building upon a previous week (like during a deload)" do
          it "uses week 2 prescription" do
            weeks = program.days[0].groups[0].exercises[0].weeks
            weeks << build(:week_prescription, build_on_week_index: nil, description: "week 2", sets: [
                build(:set_prescription, reps: 3, intensity: 70),
                build(:set_prescription, reps: 5, intensity: 60),
            ])

            session = factory.generate_training_session(user_id, program.id, day_index, week_index)

            expect(session.groups.first.exercises.first.description).to eq("week 2")
            expect(session.groups.first.exercises.first.sets.count).to eq(2)
            expect(session.groups.first.exercises.first.sets[0].reps).to eq(3)
            expect(session.groups.first.exercises.first.sets[0].weight).to eq(140)
            expect(session.groups.first.exercises.first.sets[1].reps).to eq(5)
            expect(session.groups.first.exercises.first.sets[1].weight).to eq(120)
          end
        end

        context "when building upon a previous week" do
          let(:week1_rx_id) {
            Domain::Values::PrescriptionIdentifier.new(program_id: program.id,
                                                         day_index: day_index,
                                                         group_index: 0,
                                                         exercise_index: 0,
                                                         week_index: 0)
          }
          before :each do
            weeks = program.days[0].groups[0].exercises[0].weeks
            # change across all metrics (set count, rep counts, intensities)
            weeks << build(:week_prescription, description: "week 2", build_on_week_index: 0, sets: [
                build(:set_prescription, reps: 1, intensity: 100),
                build(:set_prescription, reps: 3, intensity: 95),
                build(:set_prescription, reps: 20, intensity: 75),
            ])
          end

          it "uses week 2 prescription if week 1 history was recorded and completed as prescribed" do
            history = build(:training_history, prescription: week1_rx_id, completed_as_prescribed: true)

            allow(history_repo).to receive(:get).with(user_id, week1_rx_id).and_return(history)

            session = factory.generate_training_session(user_id, program.id, day_index, week_index)

            expect(session.groups.first.exercises.first.description).to eq("week 2")
            expect(session.groups.first.exercises.first.sets.count).to eq(3)
            expect(session.groups.first.exercises.first.sets[0].reps).to eq(1)
            expect(session.groups.first.exercises.first.sets[0].weight).to eq(200)
            expect(session.groups.first.exercises.first.sets[1].reps).to eq(3)
            expect(session.groups.first.exercises.first.sets[1].weight).to eq(190)
            expect(session.groups.first.exercises.first.sets[2].reps).to eq(20)
            expect(session.groups.first.exercises.first.sets[2].weight).to eq(150)
          end

          it "falls back to week 1 if no history is recorded for week 1" do
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
            history = build(:training_history, prescription: week1_rx_id, completed_as_prescribed: false)

            allow(history_repo).to receive(:get).with(user_id, week1_rx_id).and_return(history)

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

      context "during week 3" do
        let(:week3_rx_id) {
          Domain::Values::PrescriptionIdentifier.new(program_id: program.id,
                                                       day_index: day_index,
                                                       group_index: 0,
                                                       exercise_index: 0,
                                                       week_index: 2)
        }
        let(:week2_rx_id) {
          Domain::Values::PrescriptionIdentifier.new(program_id: program.id,
                                                       day_index: day_index,
                                                       group_index: 0,
                                                       exercise_index: 0,
                                                       week_index: 1)
        }
        let(:week1_rx_id) {
          Domain::Values::PrescriptionIdentifier.new(program_id: program.id,
                                                       day_index: day_index,
                                                       group_index: 0,
                                                       exercise_index: 0,
                                                       week_index: 0)
        }

        context "when building upon week 2 which builds upon week 1" do
          before :each do
            weeks = program.days[0].groups[0].exercises[0].weeks
            weeks << build(:week_prescription, build_on_week_index: 0, description: "week 2", sets: [
                build(:set_prescription, reps: 3, intensity: 90)
            ])
            weeks << build(:week_prescription, build_on_week_index: 1, description: "week 3", sets: [
                build(:set_prescription, reps: 3, intensity: 95),
                build(:set_prescription, reps: 5, intensity: 85)
            ])
          end


          it "uses week 3 if history was completed as prescribed for week 2" do
            week2_history = build(:training_history, prescription: week2_rx_id, completed_as_prescribed: true)

            allow(history_repo).to receive(:get).with(user_id, week2_rx_id).and_return(week2_history)

            session = factory.generate_training_session(user_id, program.id, day_index, week3_rx_id.week_index)

            expect(session.groups.first.exercises.first.description).to eq("week 3")
            expect(session.groups.first.exercises.first.sets.count).to eq(2)
            expect(session.groups.first.exercises.first.sets[0].reps).to eq(3)
            expect(session.groups.first.exercises.first.sets[0].weight).to eq(190)
            expect(session.groups.first.exercises.first.sets[1].reps).to eq(5)
            expect(session.groups.first.exercises.first.sets[1].weight).to eq(170)
          end

          it "falls back to week 2 if week 2 was not completed but week 1 was completed" do
            week1_history = build(:training_history, prescription: week1_rx_id, completed_as_prescribed: true)

            allow(history_repo).to receive(:get).with(user_id, week2_rx_id).and_return(nil)
            allow(history_repo).to receive(:get).with(user_id, week1_rx_id).and_return(week1_history)

            session = factory.generate_training_session(user_id, program.id, day_index, week3_rx_id.week_index)
            expect(session.groups.first.exercises.first.sets.count).to eq(1)
            expect(session.groups.first.exercises.first.sets[0].reps).to eq(3)
            expect(session.groups.first.exercises.first.sets[0].weight).to eq(180)
          end

          it "falls back to week 1 if no history was recorded for any previous week" do
            allow(history_repo).to receive(:get).and_return(nil)

            session = factory.generate_training_session(user_id, program.id, day_index, week3_rx_id.week_index)

            expect(session.groups.first.exercises.first.description).to eq("week 1")
            expect(session.groups.first.exercises.first.sets.count).to eq(2)
            expect(session.groups.first.exercises.first.sets[0].reps).to eq(3)
            expect(session.groups.first.exercises.first.sets[0].weight).to eq(180)
            expect(session.groups.first.exercises.first.sets[1].reps).to eq(5)
            expect(session.groups.first.exercises.first.sets[1].weight).to eq(160)
          end
        end

        context "when building upon week 1 (like when week 2 is a deload)" do
          before :each do
            weeks = program.days[0].groups[0].exercises[0].weeks
            weeks << build(:week_prescription, build_on_week_index: nil, description: "week 2", sets: [
                build(:set_prescription, reps: 3, intensity: 90)
            ])
            weeks << build(:week_prescription, build_on_week_index: 0, description: "week 3", sets: [
                build(:set_prescription, reps: 3, intensity: 95),
                build(:set_prescription, reps: 5, intensity: 85)
            ])
          end

          context "even though week 2 was completed as prescribed" do
            before :each do
              week2_history = build(:training_history, prescription: week2_rx_id, completed_as_prescribed: true)
              allow(history_repo).to receive(:get).with(user_id, week2_rx_id).and_return(week2_history)
            end

            it "falls back to week 1 if week 1 history was not recorded" do
              allow(history_repo).to receive(:get).with(user_id, week1_rx_id).and_return(nil)

              session = factory.generate_training_session(user_id, program.id, day_index, week3_rx_id.week_index)

              expect(session.groups.first.exercises.first.description).to eq("week 1")
              expect(session.groups.first.exercises.first.sets.count).to eq(2)
              expect(session.groups.first.exercises.first.sets[0].reps).to eq(3)
              expect(session.groups.first.exercises.first.sets[0].weight).to eq(180)
              expect(session.groups.first.exercises.first.sets[1].reps).to eq(5)
              expect(session.groups.first.exercises.first.sets[1].weight).to eq(160)
            end

            it "falls back to week 1 if week 1 was not completed as prescribed" do
              week1_history = build(:training_history, prescription: week1_rx_id, completed_as_prescribed: false)

              allow(history_repo).to receive(:get).with(user_id, week1_rx_id).and_return(week1_history)

              session = factory.generate_training_session(user_id, program.id, day_index, week3_rx_id.week_index)

              expect(session.groups.first.exercises.first.description).to eq("week 1")
              expect(session.groups.first.exercises.first.sets.count).to eq(2)
              expect(session.groups.first.exercises.first.sets[0].reps).to eq(3)
              expect(session.groups.first.exercises.first.sets[0].weight).to eq(180)
              expect(session.groups.first.exercises.first.sets[1].reps).to eq(5)
              expect(session.groups.first.exercises.first.sets[1].weight).to eq(160)
            end
          end

          context "even though week 2 was not completed as prescribed" do
            before :each do
              week2_history = build(:training_history, prescription: week2_rx_id, completed_as_prescribed: false)
              allow(history_repo).to receive(:get).with(user_id, week2_rx_id).and_return(week2_history)
            end
            it "uses week 3 if week 1 was completed as prescribed" do
              week1_history = build(:training_history, prescription: week1_rx_id, completed_as_prescribed: true)

              allow(history_repo).to receive(:get).with(user_id, week1_rx_id).and_return(week1_history)

              session = factory.generate_training_session(user_id, program.id, day_index, week3_rx_id.week_index)
              expect(session.groups.first.exercises.first.description).to eq("week 3")
              expect(session.groups.first.exercises.first.sets.count).to eq(2)
              expect(session.groups.first.exercises.first.sets[0].reps).to eq(3)
              expect(session.groups.first.exercises.first.sets[0].weight).to eq(190)
              expect(session.groups.first.exercises.first.sets[1].reps).to eq(5)
              expect(session.groups.first.exercises.first.sets[1].weight).to eq(170)
            end
          end
        end
      end
    end

    context "with multiple exercises" do
      let(:squat) { build(:exercise, name: "squat", id: "1") }
      let(:deadlift) { build(:exercise, name: "deadlift", id: "2") }
      before :each do
        allow(exercise_repo).to receive(:get).with(squat.id).and_return(squat)
        allow(exercise_repo).to receive(:get).with(deadlift.id).and_return(deadlift)
        allow(working_max_repo).to receive(:get).with(user_id, squat.id).and_return(200)
        allow(working_max_repo).to receive(:get).with(user_id, deadlift.id).and_return(400)
      end

      context "in separate prescription groups" do
        before :each do
          program = build(:training_program, days: [
              build(:training_day, description: "leg day", groups: [
                  build(:prescription_group, exercises: [
                      build(:exercise_prescription, exercise_id: squat.id, weeks: [
                          build(:week_prescription, description: "week 1", sets: [
                              build(:set_prescription, reps: 5, intensity: 90)
                          ]),
                          build(:week_prescription, description: "week 2", build_on_week_index: 0, sets: [
                              build(:set_prescription, reps: 3, intensity: 95)
                          ])
                      ])
                  ]),
                  build(:prescription_group, exercises: [
                      build(:exercise_prescription, exercise_id: deadlift.id, weeks: [
                          build(:week_prescription, description: "week 1", sets: [
                              build(:set_prescription, reps: 5, intensity: 80)
                          ]),
                          build(:week_prescription, description: "week 2", build_on_week_index: 0, sets: [
                              build(:set_prescription, reps: 3, intensity: 85)
                          ])
                      ])
                  ])
              ])
          ])

          allow(program_repo).to receive(:get).with(program.id).and_return(program)
        end
        context "during week 2" do
          let(:week2_index) { 1 }
          let(:week1_ex1_rx_id) {
            Domain::Values::PrescriptionIdentifier.new(program_id: program.id,
                                                         day_index: day_index,
                                                         group_index: 0,
                                                         exercise_index: 0,
                                                         week_index: 0)
          }
          let(:week1_ex2_rx_id) {
            Domain::Values::PrescriptionIdentifier.new(program_id: program.id,
                                                         day_index: day_index,
                                                         group_index: 1,
                                                         exercise_index: 0,
                                                         week_index: 0)
          }
          context "when first exercise was completed in week 1, but second exercise was not completed in week 1" do
            before :each do
              week1_ex1_history = build(:training_history, prescription: week1_ex1_rx_id, completed_as_prescribed: true)
              allow(history_repo).to receive(:get).with(user_id, week1_ex1_rx_id).and_return(week1_ex1_history)
              allow(history_repo).to receive(:get).with(user_id, week1_ex2_rx_id).and_return(nil)
            end
            it "uses week 2 prescription for first exercise, and week 1 prescription for second exercise" do
              session = factory.generate_training_session(user_id, program.id, day_index, week2_index)

              expect(session.groups[0].exercises[0].description).to eq("week 2")
              expect(session.groups[0].exercises[0].exercise.name).to eq("squat")
              expect(session.groups[0].exercises[0].sets.count).to eq(1)
              expect(session.groups[0].exercises[0].sets[0].reps).to eq(3)
              expect(session.groups[0].exercises[0].sets[0].weight).to eq(190)
              expect(session.groups[1].exercises[0].description).to eq("week 1")
              expect(session.groups[1].exercises[0].exercise.name).to eq("deadlift")
              expect(session.groups[1].exercises[0].sets.count).to eq(1)
              expect(session.groups[1].exercises[0].sets[0].reps).to eq(5)
              expect(session.groups[1].exercises[0].sets[0].weight).to eq(320)
            end
          end
        end
      end

      context "in the same prescription group (supersets)" do
        before :each do
          program = build(:training_program, days: [
              build(:training_day, description: "leg day", groups: [
                  build(:prescription_group, exercises: [
                      build(:exercise_prescription, exercise_id: squat.id, weeks: [
                          build(:week_prescription, description: "week 1", sets: [
                              build(:set_prescription, reps: 5, intensity: 90)
                          ]),
                          build(:week_prescription, description: "week 2", build_on_week_index: 0, sets: [
                              build(:set_prescription, reps: 3, intensity: 95)
                          ])
                      ]),
                      build(:exercise_prescription, exercise_id: deadlift.id, weeks: [
                          build(:week_prescription, description: "week 1", sets: [
                              build(:set_prescription, reps: 5, intensity: 80)
                          ]),
                          build(:week_prescription, description: "week 2", build_on_week_index: 0, sets: [
                              build(:set_prescription, reps: 3, intensity: 85)
                          ])
                      ])
                  ])
              ])
          ])

          allow(program_repo).to receive(:get).with(program.id).and_return(program)
        end
        context "during week 2" do
          let(:week2_index) { 1 }
          let(:week1_ex1_rx_id) {
            Domain::Values::PrescriptionIdentifier.new(program_id: program.id,
                                                         day_index: day_index,
                                                         group_index: 0,
                                                         exercise_index: 0,
                                                         week_index: 0)
          }
          let(:week1_ex2_rx_id) {
            Domain::Values::PrescriptionIdentifier.new(program_id: program.id,
                                                         day_index: day_index,
                                                         group_index: 0,
                                                         exercise_index: 1,
                                                         week_index: 0)
          }
          context "when first exercise was completed in week 1, but second exercise was not completed in week 1" do
            before :each do
              week1_ex1_history = build(:training_history, prescription: week1_ex1_rx_id, completed_as_prescribed: true)
              allow(history_repo).to receive(:get).with(user_id, week1_ex1_rx_id).and_return(week1_ex1_history)
              allow(history_repo).to receive(:get).with(user_id, week1_ex2_rx_id).and_return(nil)
            end
            it "uses week 2 prescription for first exercise, and week 1 prescription for second exercise" do
              session = factory.generate_training_session(user_id, program.id, day_index, week2_index)

              expect(session.groups[0].exercises[0].description).to eq("week 2")
              expect(session.groups[0].exercises[0].exercise.name).to eq("squat")
              expect(session.groups[0].exercises[0].sets.count).to eq(1)
              expect(session.groups[0].exercises[0].sets[0].reps).to eq(3)
              expect(session.groups[0].exercises[0].sets[0].weight).to eq(190)
              expect(session.groups[0].exercises[1].description).to eq("week 1")
              expect(session.groups[0].exercises[1].exercise.name).to eq("deadlift")
              expect(session.groups[0].exercises[1].sets.count).to eq(1)
              expect(session.groups[0].exercises[1].sets[0].reps).to eq(5)
              expect(session.groups[0].exercises[1].sets[0].weight).to eq(320)
            end
          end
        end
      end

      context "where some exercises are nil during some weeks (alternating exercises by week)" do
        before :each do
          program = build(:training_program, days: [
              build(:training_day, description: "leg day", groups: [
                  build(:prescription_group, exercises: [
                      build(:exercise_prescription, exercise_id: squat.id, weeks: [
                          build(:week_prescription, description: "week 1", sets: [
                              build(:set_prescription, reps: 5, intensity: 90)
                          ]),
                          nil,
                          build(:week_prescription, description: "week 3", build_on_week_index: 0, sets: [
                              build(:set_prescription, reps: 3, intensity: 95)
                          ]),
                          nil
                      ]),
                      build(:exercise_prescription, exercise_id: deadlift.id, weeks: [
                          nil,
                          build(:week_prescription, description: "week 2", sets: [
                              build(:set_prescription, reps: 5, intensity: 80)
                          ]),
                          nil,
                          build(:week_prescription, description: "week 4", build_on_week_index: 1, sets: [
                              build(:set_prescription, reps: 3, intensity: 85)
                          ])
                      ])
                  ])
              ])
          ])

          allow(program_repo).to receive(:get).with(program.id).and_return(program)
        end
        let(:week1_ex1_rx_id) {
          Domain::Values::PrescriptionIdentifier.new(program_id: program.id,
                                                     day_index: day_index,
                                                     group_index: 0,
                                                     exercise_index: 0,
                                                     week_index: 0)
        }
        it "does not include nil exercise in the training session" do
          session = factory.generate_training_session(user_id, program.id, day_index, week1_ex1_rx_id.week_index)

          expect(session.groups.count).to eq(1)
          expect(session.groups[0].exercises.count).to eq(1)
          expect(session.groups[0].exercises[0].description).to eq("week 1")
          expect(session.groups[0].exercises[0].exercise.name).to eq("squat")
          expect(session.groups[0].exercises[0].sets.count).to eq(1)
          expect(session.groups[0].exercises[0].sets[0].reps).to eq(5)
          expect(session.groups[0].exercises[0].sets[0].weight).to eq(180)
        end
      end
    end


  end
end
