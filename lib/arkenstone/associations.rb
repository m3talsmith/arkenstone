require 'active_support/inflector'

# TODO: consider splitting the bigger associations (has_many) into separate files
module Arkenstone
  module Associations
    module ClassMethods

      # All association data is stored in a hash (@arkenstone_data) on the instance of the class. Each entry in the hash is keyed off the association name. The value of the hash key is a basic array. This can be wrapped up and extended if (when) more functionality is needed.
      # `setup_arkenstone_data` creates the following *instance* methods on the class:
      #
      # `arkenstone_data` - the hash for the association data. Only use this if you're absolutely 100% sure that you don't need to get up to date data.
      #
      # `wipe_arkenstone_cache` - clears the cache for the association provided
      def setup_arkenstone_data

        define_method('arkenstone_data') do
          @arkenstone_data = {} if @arkenstone_data.nil?
          @arkenstone_data
        end

        define_method('wipe_arkenstone_cache') do |model_name|
          arkenstone_data[model_name] = nil
        end

      end

      # Creates a One to Many association with the supplied `child_model_name`. Example:
      #
      #     class Flea
      #     end
      #
      #     class Llama
      #       has_many :fleas
      #
      #     end
      #
      # Once `has_many` has evaluated, the structure of `Llama` will look like this:
      # 
      #     class Llama
      #       def cached_fleas
      #         #snip
      #       end
      #
      #       def fleas
      #         #snip
      #       end
      #
      #       def flea_ids
      #         [...] # all the ids of the fleas 
      #       end
      #
      #       def add_flea(new_flea)
      #         #snip
      #       end
      #
      #       def remove_flea(flea_to_remove)
      #         #snip
      #       end
      #     end
      def has_many(child_model_name)
        setup_arkenstone_data

        # The method for accessing the cached data is `cached_[name]`. If the cache is empty it creates a request to repopulate it from the server.
        cached_child_name = "cached_#{child_model_name}"
        add_association_method cached_child_name do
          cache = arkenstone_data
          if cache[child_model_name].nil?
            cache[child_model_name] = fetch_children child_model_name
          end
          cache[child_model_name]
        end

        # The uncached version is the name supplied to has_many. It wipes the cache for the association and refetches it.
        add_association_method child_model_name do 
          self.wipe_arkenstone_cache child_model_name
          self.send cached_child_name
        end

        # Creates an array of the ids of the child models for quick access.
        singular = child_model_name.to_s.singularize
        add_association_method "#{singular}_ids" do
          (self.send cached_child_name).map(&:id)
        end

        # Add a model to the association with add_[child_model_name]. It performs two network calls, one to add it, then another to refetch the association.
        add_child_method_name = "add_#{singular}"
        add_association_method add_child_method_name do |new_child|
          self.add_child child_model_name, new_child.id
          self.wipe_arkenstone_cache child_model_name
          self.send cached_child_name
        end

        # Remove a model from the association with remove_[child_model_name]. It performs two network calls, one to add it, then another to refetch the association.
        remove_child_method_name = "remove_#{singular}"
        add_association_method remove_child_method_name do |child_to_remove|
          self.remove_child child_model_name, child_to_remove.id
          self.wipe_arkenstone_cache child_model_name
          self.send cached_child_name
        end
      end

      # Similar to `has_many` but for a One to One association. Example:
      #
      #     class Hat
      #     end
      #    
      #     class Llama
      #       has_one :hat
      #     end
      #
      # Once `has_one` has evaluated, the structure of `Llama` will look like this:
      #
      #     class Llama
      #       def cached_hat
      #         #snip
      #       end
      #
      #       def hat
      #         #snip
      #       end
      #
      #       def hat=(new_value)
      #         #snip
      #       end
      #     end
      #
      # If nil is passed into the setter method (`hat=` in the above example), the association is removed.
      def has_one(child_model_name)
        setup_arkenstone_data

        # The method for accessing the cached single resource is `cached_[name]`. If the value is nil it creates a request to pull the value from the server.
        cached_child_name = "cached_#{child_model_name}"
        add_association_method cached_child_name do
          cache = arkenstone_data
          if cache[child_model_name].nil?
            cache[child_model_name] = fetch_child child_model_name
          end
          cache[child_model_name]
        end

        # The uncached version is retrieved by wiping the cache for the association, and then re-getting it.
        add_association_method child_model_name do
          arkenstone_data[child_model_name] = nil
          self.send cached_child_name
        end

        # A single association is updated or removed with a setter method.
        setter_method_name = "#{child_model_name}="
        add_association_method setter_method_name do |new_value|
          if new_value.nil?
            old_model = self.send child_model_name
            self.remove_child child_model_name, old_model.id
            self.wipe_arkenstone_cache child_model_name
          else
            self.add_child child_model_name, new_value.id
            self.wipe_arkenstone_cache child_model_name
            self.send cached_child_name
          end
        end

      end

      # The opposite of a has_X relationship. Allows you to go back up the association tree. Example:
      #
      #     class Hat
      #       belongs_to :llama
      #     end
      #
      #     class Llama
      #     end
      #
      # Once `belongs_to` has been evaluated, the structure of `Hat` will look like this:
      #
      #     class Hat
      #       def llama
      #         #snip
      #       end
      #     end
      def belongs_to(parent_model_name)
        setup_arkenstone_data

        parent_model_field = "#{parent_model_name}_id"
        
        self.arkenstone_attributes = [] unless self.arkenstone_attributes
        self.arkenstone_attributes << parent_model_field.to_sym
        class_eval("attr_accessor :#{parent_model_field}")

        # The method for accessing the cached data is `cached_[name]`. If the cache is empty it creates a request to repopulate it from the server.
        cached_parent_model_name = "cached_#{parent_model_name}"
        add_association_method cached_parent_model_name do
          cache = arkenstone_data
          if cache[parent_model_name].nil?
            cache[parent_model_name] = fetch_parent parent_model_name
          end
          cache[parent_model_name]
        end

        # The uncached version is the name supplied to belongs_to. It wipes the cache for the association and refetches it.
        add_association_method "#{parent_model_name}" do
          arkenstone_data[parent_model_name] = nil
          self.send cached_parent_model_name
        end

        define_method("#{parent_model_name}=") do |parent_instance|
          self.send "#{parent_model_field}=".to_sym, parent_instance.id
        end
      end

      ### Support for `has_and_belongs_to_many` relationship
      def has_and_belongs_to_many(model_klass_name)

        # Gather the namespace
        namespace             = self.to_s.split(/::/)
        model_klass_name      = model_klass_name.to_s.singularize.underscore.to_sym
        current_klass_name    = namespace.pop.underscore.to_sym

        # Build join class needs
        join_klass_name       = ([model_klass_name, current_klass_name].sort).join('_')
        join_klass_classified = join_klass_name.classify.to_sym
        join_klass_pluralized = join_klass_name.pluralize
        namespace             = Kernel.const_get(namespace.join('::'))

        # Create the join class if it doesn't exist already
        unless namespace.constants.include?(join_klass_classified)
          join_klass = namespace.const_set(join_klass_classified, Class.new)
          join_klass.instance_eval {include Arkenstone::Document}

          # The join class should belong to both foreign sides of the relationship
          join_klass.send :belongs_to, model_klass_name
          join_klass.send :belongs_to, current_klass_name
        end
      
        # This class should belong to the join table
        self.send(:has_many, join_klass_pluralized.to_sym) unless self.respond_to?(join_klass_pluralized.to_sym)

        # These are helper variables for the cached and uncached join `:through` instances
        model_klass_pluralized = model_klass_name.to_s.pluralize
        cached_instances_field = "cached_#{model_klass_pluralized}"

        self.send :attr_accessor, cached_instances_field.to_sym

        # Creates a `self.join_through_instances` helper method
        # 
        # This actually pulls instances of the join model and then maps on the
        # complimenting foreign key to gather all the foreign join instances
        #
        define_method "#{model_klass_pluralized}" do
          current_klass_instance   = self # The instance calling this method
          current_klass_pluralized = current_klass_name.to_s.pluralize

          # Check for cached joined instances
          cached_instances         = current_klass_instance.send cached_instances_field
          if cached_instances
            return cached_instances
          else
            # Get from joined instances
            model_klass_instances = self.send("cached_#{join_klass_pluralized}".to_sym).map(&:"#{model_klass_pluralized}")

            # Redefine `<<` so that you can something like `beer.tags << new_tag`
            model_klass_instances.define_singleton_method :<< do |element|
              # Use built in `push` for `Array.new`
              push element

              # Cache the result
              current_klass_instance.send "#{cached_instances_field}=", self

              # Add the current class instance in the other side of the join
              # The equivelant of doing `beer.tags << tag` then `tag.beers << beer`
              #
              # Grab the current_klass_instances from element
              element_current_klass_instances = element.send(current_klass_pluralized)

              # Push the current_klass_instance to what element currently has
              element_current_klass_instances = element_current_klass_instances.push(current_klass_instance)

              # Save the new stack of current_klass_instances with element
              element.send "#{current_klass_pluralized}=", element_current_klass_instances

              # Return the new array
              return self
            end
            return model_klass_instances
          end
        end

        # This creates a setter helper to set all joined instances on the
        # opposite side of the foreign join
        #
        define_method "#{model_klass_pluralized}=" do |elements|
          current_klass_instance = self
          current_klass_instance.send "#{cached_instances_field}=", elements
        end
      end
      
      # Adds a method to a class unless that method is already defined.
      def add_association_method(method_name, &method_definition)
        unless method_defined? method_name
          define_method method_name, method_definition
        end
      end
    end

    module InstanceMethods
      ### Fetches a `has_many` based resource
      def fetch_children(child_model_name)
        fetch_nested_resource child_model_name do |klass, response_body|
          klass.parse_all response_body
        end
      end

      ### Fetches a single `has_one` based resource
      def fetch_child(child_model_name)
        fetch_nested_resource child_model_name do |klass, response_body|
          return nil if response_body.nil? or response_body.empty?
          klass.build JSON.parse(response_body)
        end
      end

      ### Fetches a single `belongs_to` parent resource.
      def fetch_parent(parent_model_name)
        klass_name = parent_model_name.to_s.classify
        klass_name = prefix_with_class_module klass_name
        klass      = Kernel.const_get klass_name
        parent_model_field = "#{parent_model_name}_id"
        klass.send(:find, self.send(parent_model_field))
      end

      ### Calls the POST url for creating a nested_resource
      def add_child(child_model_name, child_id)
        url = build_nested_url child_model_name
        body = {id: child_id}.to_json
        self.class.send_request url, :post, body
      end

      ### Calls the DELETE route for a nested resource
      def remove_child(child_model_name, child_id)
        url = build_nested_url child_model_name, child_id
        self.class.send_request url, :delete
      end

      private

      ### Creates the network request for fetching a child resource. Hands parsing the response off to a callback. 
      def fetch_nested_resource(nested_resource_name, &parser)
        url = build_nested_url nested_resource_name
        response = self.class.send_request url, :get
        return [] unless self.class.response_is_success response
        klass_name = nested_resource_name.to_s.classify
        klass_name = prefix_with_class_module klass_name
        klass = Kernel.const_get klass_name 
        parser[klass, response.body]
      end

      # If the class is in a module, preserve the module namespace.
      # Example:
      #     
      #     # for the class Zoo::Llama
      #     prefix_with_class_module('Hat') # 'Zoo::Hat'
      def prefix_with_class_module(klass)
        mod = self.class.name.deconstantize
        klass = "#{mod}::#{klass}" unless mod.empty?
        klass
      end

      # Builds a RESTful nested URL based on the instance URL.
      # Example:
      #
      #     build_nested_url('fleas') # http://example.com/llamas/100/fleas
      #     build_nested_url('fleas', 25) # http://example.com/llamas/100/fleas/25
      def build_nested_url(child_name, child_id = nil)
        url = "#{self.instance_url}/#{child_name}"
        url += "/#{child_id}" unless child_id.nil?
        url
      end

    end
  end

end
