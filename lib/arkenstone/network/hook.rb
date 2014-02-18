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

      def call_hook(klass, enumerator)
        hooks = []
        if klass.arkenstone_inherit_hooks == true
          klass.ancestors.each do |ancestor|
            break if     ancestor == Arkenstone::Associations::InstanceMethods
            break unless ancestor.respond_to?(:arkenstone_hooks)
            hooks.concat ancestor.arkenstone_hooks unless ancestor.arkenstone_hooks.nil?
          end
        else
          hooks = klass.arkenstone_hooks
        end
        hooks.each(&enumerator) unless hooks.nil?
      end
    end
  end
end
