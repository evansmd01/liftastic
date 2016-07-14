require 'factory_girl'
require_relative '../../app/domain/entities/training_program'

FactoryGirl.define do
  factory :exercise, class: Domain::Entities::Exercise do
    id "1"
    name "Back Squat"
  end
end