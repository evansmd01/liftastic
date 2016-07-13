require 'virtus'

module Domain
  module Entities
    include Virtus.model

    attribute :id, String
    attribute :name, String
    attribute :description, String
  end
end