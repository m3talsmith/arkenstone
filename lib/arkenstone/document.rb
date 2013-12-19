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
      attr_accessor :arkenstone_json, :arkenstone_attributes, :id
      def attributes
        @arkenstone_attributes ||= JSON.parse(self.arkenstone_json)
      end

      def attributes=(options)
        self.arkenstone_json = options.to_json
        options.each do |key, value|
          self.send("#{key}=".to_sym, value) if self.respond_to? key
        end
        self.attributes
      end

      def to_json
        self.attributes.to_json
      end

      def save
        self.id = 1
        self.timestamp if self.respond_to?(:timestampable)
        return self
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

      def create(options)
        document = self.build(options)
        document.save
      end
    end
  end
end

