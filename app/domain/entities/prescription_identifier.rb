require 'virtus'

module Domain
  module Entities
    class PrescriptionIdentifier
      include Virtus.model

      attribute :program_id, String
      attribute :day_index, Integer
      attribute :group_index, Integer
      attribute :exercise_index, Integer
      attribute :week_index, Integer
    end
  end
end