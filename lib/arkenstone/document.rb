require 'json'

module Arkenstone
  # # Document
  #
  # A `Document` is the main entry point for Arkenstone. A `Document` is a model that is retrieved and/or stored on a RESTful service. For example, if you have a web service that has a URL structure like:
  #
  #     http://example.com/users
  #
  # You can create a `User` model, include `Document` and it will automatically create methods to fetch and save data from that URL.
  #
  #     class User
  #       include Arkenstone::Document
  #
  #       url 'http://example.com/users'
  #
  #       attributes :first_name, :last_name, :email
  #     end
  #
  # Attributes create properties on instances that match up with the data returned by the `url`. Properties on the web service are ignored if they are not present within the `attributes` list.
  module Document
    class << self
      def included(base)
        base.send :include, Arkenstone::Helpers
        base.send :include, Arkenstone::Associations
        base.send :include, Arkenstone::Document::InstanceMethods
        base.send :include, Arkenstone::Network
        base.extend Arkenstone::Document::ClassMethods
      end
    end

    module InstanceMethods
      ### The convention is for all Documents to have an id. 
      attr_accessor :id, :arkenstone_attributes

      ### Easy access to all of the attributes defined for this Document.
      def attributes
        new_hash = {}
        self.class.arkenstone_attributes.each do |key|
          new_hash[key.to_sym] = self.send("#{key}")
        end
        new_hash
      end

      ### Set attributes for a Document. If a key in the `options` hash is not present in the attributes list, it is ignored.
      def attributes=(options)
        options.each do |key, value|
          self.send("#{key}=".to_sym, value) if self.respond_to? key
        end
        self.attributes
      end

      ### Serializes the attributes to json.
      def to_json
        self.attributes.to_json
      end

      ### If this is a new Document, create it with a POST request, otherwise update it with a PUT.
      def save
        self.class.check_for_url
        self.timestamp if self.respond_to?(:timestampable)
        response             = self.id ? put_document_data : post_document_data
        self.attributes      = JSON.parse(response.body)
        return self
      end


      ### Reloading the document fetches the document again by it's id
      def reload
        reloaded_self = self.class.find(self.id)
        self.attributes = reloaded_self.attributes
        return self
      end

      alias_method :save!, :save

      ### Update a single attribute. Performs validation (by calling `update_attributes`).
      def update_attribute(key, value)
        hash = { key.to_sym => value }
        self.update_attributes hash
      end

      ### Update multiple attributes at once. Performs validation (if that is setup for this document).
      def update_attributes(new_attributes)
        original_attrs = self.attributes.clone
        self.attributes = self.attributes.merge! new_attributes
        if has_validation_method?
          save_if_valid original_attrs
        else
          self.save
        end
      end

      # If a model passes validation, it is saved, otherwise the original attributes (`original_attrs`) are reset.
      # Assumes there is a validation method defined for the Document.
      def save_if_valid(original_attrs)
        if self.valid?
          self.save
        else
          self.attributes = original_attrs
          false
        end
      end

      ### Checks if there is a `valid?` method.
      def has_validation_method?
        self.class.method_defined? :valid?
      end

      # Retrieves a RESTful URL for an instance, in this case by tacking an id onto the end of the `arkenstone_url`.
      # Example:
      #
      #     # arkenstone_url
      #     http://example.com/users
      #
      #     # instance_url
      #     http://example.com/users/100
      def instance_url
        "#{full_url(self.class.arkenstone_url)}#{id}"
      end

      ### The full RESTful URL for a Document.
      def class_url
        full_url(self.class.arkenstone_url)
      end

      ### Save via POST.
      def post_document_data
        http_response class_url, :post
      end

      ### Save via PUT.
      def put_document_data
        http_response instance_url, :put
      end

      ### Sends a DELETE request to the `instance_url`.
      def destroy
        resp = http_response instance_url, :delete
        Arkenstone::Network.response_is_success resp
      end

      ### Sends a network request with the `attributes` as the body.
      def http_response(url, method=:post)
        self.class.send_request url, method, saveable_attributes
      end

      def saveable_attributes
        return self.attributes if self.class.arkenstone_hooks.nil?
        attrs = {}
        self.class.arkenstone_hooks.each do |hook|
          new_attrs = hook.encode_attributes(self.attributes)
          attrs.merge! new_attrs unless new_attrs.nil?
        end
        attrs.empty? ? self.attributes : attrs
      end

      private
    end

    module ClassMethods
      attr_accessor :arkenstone_url, :arkenstone_attributes, :arkenstone_hooks, :arkenstone_inherit_hooks

      ### Sets the root url used for generating RESTful requests.
      def url(new_url)
        self.arkenstone_url = new_url
      end

      # == Hooks
      #
      # Hooks are used to allow you to call arbitrary code at various points in the object lifecycle. For example, if you need to massage some property names before they are sent off to the `url`, you can do that with a hook. A hook should extend `Arkenstone::Hook` and then override the method you want to hook into. There are three types of hooks:
      # 1. `before_request` - Called before the request is sent to the web service. Passes in the request environment (an `Arkenstone::Environment`) as a parameter.
      # 2. `after_complete` - Called after the request has been *successfully* completed. Passes in a Net::HTTPResponse as a parameter.
      # 3. `on_error` - Called if the response returned an error. Passes in a Net::HTTPResponse as a parameter.
      #
      # Example:
      #
      #     class ErrorLogger < Arkenstone::Hook
      #       def on_error(response)
      #         # log the error here
      #       end
      #     end
      #
      #     class User
      #       include Arkenstone::Document
      #
      #       url 'http://example.com/users'
      #       add_hook ErrorLogger.new
      #     end
      def add_hook(hook)
        self.arkenstone_hooks = [] if self.arkenstone_hooks.nil?
        self.arkenstone_hooks << hook
      end

      # Hooks are applied **only** to the class they are added to. This can cause a problem if you have a base class and want to use the same hooks for subclasses. If you want to use the same hooks as a parent class, use `inherit_hooks`. This will tell Arkenstone to walk up the inheritance chain and call all of the hooks it can find.
      # Example:
      #
      #     class ErrorLogger < Arkenstone::Hook
      #       def on_error(response)
      #         # log the error here
      #       end
      #     end
      #
      #     class BaseModel
      #       include Arkenstone::Document
      #
      #       add_hook ErrorLogger.new
      #       add_hook SomeOtherHook.new
      #     end
      #
      #     class User < BaseModel
      #       url 'http://example.com/users'
      #
      #       inherit_hooks
      #     end
      #       
      # This will use the hooks defined for `BaseModel` and any defined for `User` too.
      def inherit_hooks(val = true)
        self.arkenstone_inherit_hooks = val
      end

      ### Sets the attributes for an Arkenstone Document. These become `attr_accessors` on instances.
      def attributes(*options)
        self.arkenstone_attributes = options
        options.each do |option|
          send(:attr_accessor, option)
        end
        return self.arkenstone_attributes
      end
      
      ### You can use Arkenstone without defining a `url`, but you won't be able to save a model without one. This raises an error if the url is not defined.
      def check_for_url
        raise NoUrlError.new, NoUrlError.default_message if self.arkenstone_url.nil?
      end

      ### Constructs a new instance with the provided attributes.
      def build(options)
        document = self.new
        document.attributes = options.select do |key, value|
          document.respond_to? :"#{key}="
        end
        return document
      end

      ### Builds a list of objects with attributes set from a JSON string.
      def parse_all(json)
        return [] if json.nil? or json.empty?
        tree = JSON.parse json
        documents = tree.map {|document| self.build document}
        Arkenstone::QueryList.new documents
      end

      ### Creates and saves a single instance with the attribute values provided.
      def create(options)
        document = self.build(options)
        document.save
      end

      ### Performs a GET request to the instance url with the supplied id. Builds an instance with the response.
      def find(id)
        check_for_url
        url      = full_url(self.arkenstone_url) + id.to_s
        response = send_request url, :get
        return nil unless Arkenstone::Network.response_is_success response
        self.build JSON.parse(response.body)
      end

      ### Calls the `arkenstone_url` expecting to receive a json array of properties to deserialize into a list of objects.
      def all
        check_for_url
        response        = send_request self.arkenstone_url, :get
        documents       = parse_all response.body
        return documents
      end
    end
  end
end

