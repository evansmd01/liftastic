require 'virtus'

module Domain
  module Entities
    class PrescriptionIdentifier
      include Virtus.model

      attribute :template_id, String
      attribute :complex_number, Integer
      attribute :exercise_number, Integer
      attribute :day_number, Integer
      attribute :week_number, Integer
    end

    class SetHistory
      include Virtus.model

      attribute :reps, Integer
      attribute :weight, Float
    end

    class TrainingHistory
      include Virtus.model

      attribute :user_id, String
      attribute :exercise_id, String
      attribute :units, String
      attribute :completed_on, Date
      attribute :based_on, PrescriptionIdentifier
      attribute :sets, Array[SetHistory]
    end
  end
end