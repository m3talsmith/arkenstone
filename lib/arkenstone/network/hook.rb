module Arkenstone
  class Hook
    def before_request(env)
    end

    def after_complete(response)
    end

    def encode_attributes(attributes)
    end

    def on_error(response)
    end

    class << self
      ### Calls all of the available `before_request` hooks available for the class.
      def call_request_hooks(klass, request)
        call_hook klass, Proc.new { |h| h.before_request request }
      end

      ### Calls all of the available `after_complete` hooks available for the class.
      def call_response_hooks(klass, response)
        call_hook klass, Proc.new { |h| h.after_complete response }
      end

      ### Calls all of the available `on_error` hooks available for the class.
      def call_error_hooks(klass, response)
        call_hook klass, Proc.new { |h| h.on_error response }
      end

      def all_hooks_for_class(klass)
        all_hooks = []
        if klass.arkenstone_inherit_hooks
          klass.ancestors.each do |ancestor|
            break if     ancestor == Arkenstone::Associations::InstanceMethods
            break unless ancestor.respond_to?(:arkenstone_hooks)
            all_hooks.concat ancestor.arkenstone_hooks unless ancestor.arkenstone_hooks.nil?
          end
        else
          all_hooks = klass.arkenstone_hooks
        end
        all_hooks
      end

      def has_hooks?(klass)
        return true if klass_has_hooks? klass
        if klass.respond_to?(:arkenstone_inherit_hooks) && klass.arkenstone_inherit_hooks
          return klass.ancestors.any? { |ancestor| klass_has_hooks? ancestor }
        end
        false
      end

      def klass_has_hooks?(klass)
        klass.respond_to?(:arkenstone_hooks) and klass.arkenstone_hooks and klass.arkenstone_hooks.count > 0
      end

      def call_hook(klass, enumerator)
        hooks = []
        if klass.arkenstone_inherit_hooks == true
          klass.ancestors.each do |ancestor|
            break if     ancestor == Arkenstone::Associations::InstanceMethods
            if ancestor.respond_to? :arkenstone_hooks and !ancestor.arkenstone_hooks.nil?
              hooks.concat ancestor.arkenstone_hooks
            end
          end
        else
          hooks = klass.arkenstone_hooks
        end
        hooks.each(&enumerator) unless hooks.nil?
      end
    end
  end
end
