module Domain
  module Entities
    class DomainAggregate
      def deep_attributes
        DomainAggregate.to_hash_recursive(self)
      end

      def self.to_hash_recursive(object)
        hash = object.to_hash
        hash.each_pair do  |key, value|
          if value.respond_to?(:each) && value.count > 0 && value.first.respond_to?(:to_hash)
            hash[key] = value.map{ |item| self.to_hash_recursive(item) }
          elsif value.respond_to?(:to_hash)
            hash[key] = self.to_hash_recursive(value)
          end
        end
        hash
      end
    end
  end
end
