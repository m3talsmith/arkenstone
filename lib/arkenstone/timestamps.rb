module Arkenstone
  module Timestamps
    class << self
      def included(base)
        base.send :include, Arkenstone::Timestamps::InstanceMethods
      end
    end
    
    module InstanceMethods
      attr_accessor :created_at, :updated_at
      def timestampable; return true; end
      def timestamp
        current_time = Time.now
        self.created_at = current_time unless self.created_at
        self.updated_at = current_time
      end
    end
  end
end
