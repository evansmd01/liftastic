require 'virtus'

module Domain
  module Entities
    class Exercise
      include Virtus.model

      attribute :id, String
      attribute :name, String
      attribute :description, String
    end
  end
end