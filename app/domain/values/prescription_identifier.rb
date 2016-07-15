require 'virtus'

module Domain
  module Values
    class PrescriptionIdentifier
      include Virtus.value_object

      values do
        attribute :program_id, String
        attribute :day_index, Integer
        attribute :group_index, Integer
        attribute :exercise_index, Integer
        attribute :week_index, Integer
      end

      def copy(options = {})

        PrescriptionIdentifier.new(
          program_id: options[:program_id] || program_id,
          day_index: options[:day_index] || day_index,
          group_index: options[:group_index] || group_index,
          exercise_index: options[:exercise_index] || exercise_index,
          week_index: options[:week_index] || week_index
        )
      end
    end
  end
end

