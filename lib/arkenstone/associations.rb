require 'active_support/inflector'

module Arkenstone
  module Associations
    module ClassMethods
      class << self
        def extended(base)
        end
      end

      def has_many(child_model_name)
        # All association data is stored in a hash (@arkenstone_data) on the instance of the class.

        # Create a cached collection for the association. Only use this if you're absolutely 100% sure that you don't need to get up to date data.
        define_method('arkenstone_data') do
          @arkenstone_data = {} if @arkenstone_data.nil?
          @arkenstone_data
        end

        # Clears a cache for a model
        define_method('wipe_arkenstone_cache') do |model_name|
          arkenstone_data[model_name] = nil
        end

        # The method for accessing the cached data is `cached_[name]`. If the cache is empty it creates a request to repopulate it from the server.
        cached_child_name = "cached_#{child_model_name}"
        define_method(cached_child_name) do
          cache = arkenstone_data
          if cache[child_model_name].nil?
            cache[child_model_name] = fetch_children child_model_name
          end
          cache[child_model_name]
        end

        # The uncached version is the name supplied to has_many. It wipes the cache for the association and refetches it.
        define_method(child_model_name) do 
          self.wipe_arkenstone_cache child_model_name
          self.send cached_child_name.to_sym
        end

        # Add a model to the association with add_[child_model_name]. It performs two network calls, one to add it, then another to refetch the association.
        singular = child_model_name.to_s.singularize
        add_child_method_name = "add_#{singular}"
        define_method(add_child_method_name) do |new_child|
          self.add_child child_model_name, new_child.id
          self.wipe_arkenstone_cache child_model_name
          self.send cached_child_name.to_sym
        end

        # Remove a model from the association with remove_[child_model_name]. It performs two network calls, one to add it, then another to refetch the association.
        remove_child_method_name = "remove_#{singular}"
        define_method(remove_child_method_name) do |child_to_remove|
          self.remove_child child_model_name, child_to_remove.id
          self.wipe_arkenstone_cache child_model_name
          self.send cached_child_name.to_sym
        end
      end

      def has_one(child_model_name)

        cached_child_name = "cached_#{child_model_name}"
        define_method(cached_child_name) do
          @arkenstone_data = {} if @arkenstone_data.nil?
          cache = @arkenstone_data
          if cache[child_model_name].nil?
            cache[child_model_name] = fetch_child child_model_name
          end
          cache[child_model_name]
        end

        define_method(child_model_name) do
          @arkenstone_data = {} if @arkenstone_data.nil?
          cache = @arkenstone_data
          cache[child_model_name] = nil
          self.send cached_child_name
        end

      end
    end


    module InstanceMethods
      def fetch_children(child_model_name)
        fetch_nested_resource child_model_name do |klass, response_body|
          klass.parse_all response_body
        end
      end

      def fetch_child(child_model_name)
        fetch_nested_resource child_model_name do |klass, response_body|
          klass.build JSON.parse(response_body)
        end
      end

      def add_child(child_model_name, child_id)
        url = build_nested_url child_model_name
        body = {id: child_id}.to_json
        self.class.send_request url, :post, body
      end

      def remove_child(child_model_name, child_id)
        url = build_nested_url child_model_name, child_id
        self.class.send_request url, :delete
      end

      private
      def fetch_nested_resource(nested_resource_name, &parser)
        url = build_nested_url nested_resource_name
        response = self.class.send_request url, :get
        klass_name = nested_resource_name.to_s.classify
        klass = Kernel.const_get klass_name
        parser[klass, response.body]
      end


      def build_nested_url(child_name, child_id = nil)
        url = "#{self.instance_url}/#{child_name}"
        url += "/#{child_id}" unless child_id.nil?
        url
      end

    end
  end

end
