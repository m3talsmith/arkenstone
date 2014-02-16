module Arkenstone
  module Associations
    module Resources
      class << self
        def included(base)
          base.send :include, InstanceMethods
          base.extend ClassMethods
        end
      end

      module ClassMethods
      end

      module InstanceMethods
        ### Attaches singleton methods for has_many relationships
        def attach_nested_has_many_resource_methods(nested_resources, nested_resource_name)
          parent_instance = self
          parent_instance.extend HasManyParentSingletonMethods
          parent_instance.add_resource_methods(nested_resource_name)

          nested_klass = prefix_with_class_module(nested_resource_name.to_s.classify)
          nested_klass = Kernel.const_get(nested_klass)
          nested_klass.url build_nested_url(nested_resource_name)

          nested_resources.define_singleton_method(:arkenstone_parent_instance) { parent_instance }
          nested_resources.define_singleton_method(:arkenstone_nested_class) { nested_klass }
          nested_resources.define_singleton_method(:arkenstone_nested_resource_name) { nested_resource_name }
          nested_resources.extend HasManySingletonMethods
          return nested_resources
        end
      end

      module HasManyParentSingletonMethods
        def add_resource_methods(nested_resource_name)
          parent_instance          = self
          resource_name_pluralized = nested_resource_name.to_s.pluralize

          parent_instance.define_singleton_method "#{resource_name_pluralized}=" do |resources|
            resources.each do |resource|
              resource.send "#{parent_instance.class.to_s.demodulize.downcase}_id=", parent_instance.id
            end

            parent_instance.arkenstone_data[resource_name_pluralized.to_sym] = resources
            return resources
          end
        end
      end

      module HasManySingletonMethods
        def <<(resource)
          push resource
          arkenstone_parent_instance.send "#{arkenstone_nested_resource_name}=", self
        end

        def build(options)
          parent_id                 = "#{arkenstone_parent_instance.class.to_s.demodulize.underscore}_id"
          new_resource              = arkenstone_nested_class.build(options.merge({parent_id => arkenstone_parent_instance.id}))
          parent_resource_instances = arkenstone_parent_instance.send arkenstone_nested_resource_name.to_sym

          parent_resource_instances << new_resource
          arkenstone_parent_instance.send "#{arkenstone_nested_resource_name}=", parent_resource_instances

          return new_resource
        end

        def create(options)
          new_resource = build(options)
          new_resource.save
        end
      end
    end
  end
end
