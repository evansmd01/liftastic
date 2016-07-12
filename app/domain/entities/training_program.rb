require 'virtus'

module Domain
  module Entities
    class IntensityPrescription
      include Virtus.module

      attribute :percent, Float
      attribute :increase, Float
    end
    class SetPrescription
      include Virtus.module

      attribute :reps, Integer
      attribute :intensity, IntensityPrescription
    end
    class WeekPrescription
      include Virtus.module

      attribute :description, String
      attribute :build_on_week, Integer
      attribute :sets, Array[SetPrescription]
    end
    class ExercisePrescription
      include Virtus.module

      attribute :exerciseId, String
      attribute :weeks, Array[WeekPrescription]
    end
    class TrainingDay
      include Virtus.module

      attribute :exercises, Array[ExercisePrescription]
    end
    class TrainingProgram
      include Virtus.module


      attribute :id, String
      attribute :training_days, Array[TrainingDay]
    end
  end
end