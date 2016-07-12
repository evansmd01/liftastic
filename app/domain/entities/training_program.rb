require 'virtus'

module Domain
  module Entities
    class IntensityPrescription
      include Virtus.model

      attribute :percent, Float
      attribute :increase, Float
    end

    class SetPrescription
      include Virtus.model

      attribute :reps, Integer
      attribute :intensity, IntensityPrescription
    end

    class WeekPrescription
      include Virtus.model

      attribute :description, String
      attribute :build_on_week, Integer
      attribute :sets, Array[SetPrescription]
    end

    class ExercisePrescription
      include Virtus.model

      attribute :exercise_id, String
      attribute :weeks, Array[WeekPrescription]
    end

    class ComplexPrescription
      include Virtus.model

      attribute :description, String
      attribute :exercises, Array[ExercisePrescription]
    end

    class TrainingDay
      include Virtus.model

      attribute :description, String
      attribute :complexes, Array[ComplexPrescription]
    end

    class TrainingProgram
      include Virtus.model

      attribute :id, String
      attribute :days, Array[TrainingDay]
    end
  end
end