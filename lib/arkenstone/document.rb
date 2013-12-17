require 'json'

module Arkenstone
  module Document
    class << self
      def included(base)
        base.send :include, Arkenstone::Document::InstanceMethods
        base.extend Arkenstone::Document::ClassMethods
      end
    end

    module InstanceMethods
      attr_accessor :arkenstone_json, :arkenstone_attributes
      def attributes
        @arkenstone_attributes ||= JSON.parse(self.arkenstone_json)
        @arkenstone_attributes
      end

      def attributes=(options)
        self.arkenstone_json = options.to_json
        options.each do |k,v|
          self.send("#{k}=".to_sym, v) if self.respond_to? k
        end
        self.attributes
      end
    end

    module ClassMethods
      attr_accessor :arkenstone_url, :arkenstone_attributes

      def url(new_url)
        self.arkenstone_url = new_url
      end

      def attributes(*options)
        self.arkenstone_attributes = options
        class_eval("attr_accessor :#{options.join(', :')}")
        return self.arkenstone_attributes
      end

      def build(options)
        document = self.new
        document.attributes = options
        return document
      end
    end
  end
end

