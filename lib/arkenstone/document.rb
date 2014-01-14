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
        self.timestamp if self.respond_to?(:timestampable)
        response             = self.id ? put_document_data : post_document_data
        self.arkenstone_json = response.body
        self.attributes      = JSON.parse(response.body)
        return self
      end

      def update_attribute(key, value)
        hash = { key.to_sym => value }
        self.update_attributes hash
      end

      def update_attributes(new_attributes)
        old_attributes = self.attributes
        old_attributes.merge! new_attributes
        self.attributes = old_attributes
        self.save
      end

      def instance_uri
        URI.parse "#{self.class.arkenstone_url}#{id}"
      end

      def class_uri
        URI.parse self.class.arkenstone_url
      end

      def post_document_data
        http_response class_uri, :post
      end

      def put_document_data
        http_response instance_uri, :put
      end

      def destroy
        resp = http_response instance_uri, :delete
        response_is_success resp
      end

      def http_response(uri, method=:post)
        request = eval("Net::HTTP::#{method.capitalize}.new(uri)")
        request.set_form_data self.attributes
        http = Net::HTTP.new(uri.hostname, uri.port)
        http.use_ssl = true if uri.scheme == 'https'
        http.request(request)
      end

      private
      def response_is_success(response)
        response.code == "200"
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
        uri      = URI.parse self.arkenstone_url + id.to_s
        response = Net::HTTP.get_response uri
        return nil unless response.code == '200'
        self.build JSON.parse response.body
      end

      def all
        uri             = URI.parse self.arkenstone_url
        response        = Net::HTTP.get_response uri
        parsed_response = JSON.parse response.body
        documents       = parsed_response.map {|document| self.build document}
        return documents
      end
    end
  end
end

