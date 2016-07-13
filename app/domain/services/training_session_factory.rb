require_relative '../entities/training_session'
require_relative '../entities/prescription_identifier'

module Domain
  module Services
    class TrainingSessionFactory

      def initialize(program_repository, history_repository, working_max_repository, exercise_repository)
        @program_repository = program_repository
        @history_repository = history_repository
        @working_max_repository = working_max_repository
        @exercise_repository = exercise_repository
      end

      def generate_training_session(user_id, program_id, day_index, week_index)
        session = TrainingSession.new(groups: [], description: training_day.description)

        # abbreviation '_rx' = '_prescription'
        program = @program_repository.get(program_id)
        day_rx = program.days[day_index]

        day_rx.groups.each_with_index do |group_rx, group_rx_index|
          session_group = SessionGroup.new(exercises: [])
          session.groups << session_group

          group_rx.exercises.each_with_index do |ex_rx, ex_rx_index|
            # a nil week prescription means we shouldn't add this exercise to the session this week.
            # this would happen in the case of alternating an exercise every other week,
            # or in the case of phasing exercises, like doing an exercise during only the first half of the program
            next if ex_rx.weeks[week_index].nil?

            exercise = @exercise_repository.get(ex_rx.exercise_id)
            session_exercise = SessionExercise.new(exercise: exercise, sets: [])
            session_group.exercises << session_exercise

            week_rx = recursively_find_week_rx(user_id, ex_rx, PrescriptionIdentifier.new(
                                                program_id: program_id,
                                                day_index: day_index,
                                                group_index: group_rx_index,
                                                exercise_index: ex_rx_index,
                                                week_index: week_index))

            working_max = @working_max_repository.get(user_id, ex_rx.exercise_id)
            week_rx.sets.each_with_index do |set_rx, set_rx_index|
              session_set = SessionSet.new(reps: set_rx.reps)
              session_exercise.sets << session_set
              session_set.intensity = recursively_calculate_intensity(week_rx, ex_rx, set_rx_index)
              session_set.weight = working_max * (session_set.intensity/100)
            end
          end
        end

        session
      end

      #region private
      private

      def recursively_find_week_rx(user_id, ex_rx, rx_id)
        week_rx = ex_rx[rx_id.week_index]
        return week_rx if week_rx.builds_on_week.nil?

        history = @history_repository.get(user_id, rx_id)
        return week_rx unless history.nil? || !history.completed_as_prescribed?

        # the user didn't finish the week that this week was supposed to build upon,
        # so they should repeat the incomplete week's prescription
        rx_id.week_index = week_rx.builds_on_week
        recursively_find_week_rx(user_id, ex_rx, rx_id)
      end

      def recursively_calculate_intensity(week_rx, ex_rx, set_rx_index)
        total_intensity = week_rx.sets[set_rx_index].intensity
        return total_intensity if week_rx.build_on_week.nil?

        week_rx = ex_rx[week_rx.build_on_week]
        total_intensity + recursively_calculate_intensity(week_rx, ex_rx, set_rx_index)
      end
      #endregion
    end
  end
end