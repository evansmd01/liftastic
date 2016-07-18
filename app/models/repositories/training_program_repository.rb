require_relative '../../domain/entities/training_program'

class TrainingProgramRepository < ActiveRecordRepository
  self.entity_type = Domain::Entities::TrainingProgram
  self.record_type = TrainingProgramRecord
end