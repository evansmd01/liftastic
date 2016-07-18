module ActiveRecordRepositoryTypes
  attr_accessor :entity_type
  attr_accessor :record_type
end

class ActiveRecordRepository
  extend ActiveRecordRepositoryTypes

  def initialize
    @entity_type = self.class.entity_type
    @record_type = self.class.record_type
  end

  def serialize(entity)
    @record_type.new(entity.deep_attributes)
  end

  def deserialize(record)
    @entity_type.new(record.attributes)
  end

  def get(id)
    record = @record_type.find(id)
    @entity_type.new(record.attributes)
  end

  def insert(entity)
    record = @record_type.new(entity.deep_attributes)
    record.save
    entity.id = record.id
  end
end
