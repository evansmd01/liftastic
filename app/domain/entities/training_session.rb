require 'virtus'
require_relative 'exercise'

module Domain
  module Entities
    class SessionSet
      include Virtus.model

      attribute :reps, Integer
      attribute :weight, Float
      attribute :intensity, Float
    end

    class SessionExercise
      include Virtus.model

      attribute :exercise, Exercise
      attribute :description, String
      attribute :sets, Array[SessionSet]
    end

    class SessionGroup
      include Virtus.model

      attribute :exercises, Array[SessionExercise]
      def superset?
        exercises.count > 1
      end
    end

    class TrainingSession
      include Virtus.model

      attribute :description, String
      attribute :groups, Array[SessionGroup]
    end
  end
end