module Arkenstone
  module Validation
    class ValidationError
      attr_accessor :messages

      def initialize
        @messages = {}
      end

      def count
        @messages.count
      end

      def [](key)
        @messages[key]
      end

      def []=(key, val)
        @messages[key] = val
      end

      def add(attr, message)
        errors_for_attr = @messages[attr]
        if errors_for_attr.nil?
          @messages[attr] = [message]
        else
          errors_for_attr << message
        end
      end

    end
  end
end
