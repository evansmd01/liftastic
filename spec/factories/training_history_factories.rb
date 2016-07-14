require 'factory_girl'
require_relative '../../app/domain/entities/training_history'

FactoryGirl.define do
  factory :training_history, class: Domain::Entities::TrainingHistory do
    sets { [
        build(:set_factory)
    ]}
  end

  factory :set_factory, class: Domain::Entities::SetHistory do

  end

end