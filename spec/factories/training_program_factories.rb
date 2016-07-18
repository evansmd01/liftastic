require 'factory_girl'
require_relative '../../app/domain/entities/training_program'

FactoryGirl.define do
  factory :training_program, class: Domain::Entities::TrainingProgram do
    name "dummy training program"
    days { [
        build(:training_day, description: "Day 1")
    ]}
  end

  factory :training_day, class: Domain::Entities::TrainingDay do

    groups { [
        build(:prescription_group)
    ]}
  end

  factory :prescription_group, class: Domain::Entities::PrescriptionGroup do
    exercises { [
        build(:exercise_prescription)
    ]}
  end

  factory :exercise_prescription, class: Domain::Entities::ExercisePrescription do

    exercise_id "1"
    weeks { [
        build(:week_prescription)
    ]}
  end

  factory :week_prescription, class: Domain::Entities::WeekPrescription do

    build_on_week_index nil
    sets { [
        build(:set_prescription, reps: 3, intensity: 90),
        build(:set_prescription, reps: 5, intensity: 80),
        build(:set_prescription, reps: 5, intensity: 80),
    ]}
  end

  factory :set_prescription, class: Domain::Entities::SetPrescription do
    reps 3
    intensity 90
  end
end
