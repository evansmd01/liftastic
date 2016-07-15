require 'virtus'

module Domain
  module Entities
    class SetPrescription
      include Virtus.model

      attribute :reps, Integer
      attribute :intensity, Float
    end

    class WeekPrescription
      include Virtus.model

      attribute :description, String
      attribute :build_on_week_index, Integer
      attribute :sets, Array[SetPrescription]
    end

    class ExercisePrescription
      include Virtus.model

      attribute :exercise_id, String
      attribute :weeks, Array[WeekPrescription]
    end

    class PrescriptionGroup
      include Virtus.model

      attribute :exercises, Array[ExercisePrescription]
    end

    class TrainingDay
      include Virtus.model

      attribute :description, String
      attribute :groups, Array[PrescriptionGroup]
    end

    class TrainingProgram
      include Virtus.model

      attribute :id, String
      attribute :days, Array[TrainingDay]
    end
  end
end