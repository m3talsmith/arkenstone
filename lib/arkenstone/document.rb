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
        new_hash = {}
        self.class.arkenstone_attributes.each do |key|
          new_hash[key.to_sym] = self.send("#{key}")
        end
        self.arkenstone_json = new_hash.to_json
        new_hash
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

      def find(id)
        # create url
        # call it
        uri = URI.parse User.arkenstone_url + id.to_s
        response_string = Net::HTTP.get uri
        self.build JSON.parse response_string
      end
    end
  end
end

