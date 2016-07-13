require 'virtus'
require 'prescription_identifier'

module Domain
  module Entities
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
      attribute :prescription, PrescriptionIdentifier
      attribute :sets, Array[SetHistory]
      attribute :completed_as_prescribed?, Boolean
    end
  end
end