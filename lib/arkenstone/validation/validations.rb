module Arkenstone
  module Validation
    class << self
      def included(base)
        base.send :include, Arkenstone::Validation::InstanceMethods
        base.extend Arkenstone::Validation::ClassMethods
      end
    end    

    module InstanceMethods
      attr_accessor :errors

      ### Does a model's attributes pass all of the validation requirements?
      def valid?
        validate
        @errors.count == 0
      end

      # Run through all the validators. 
      def validate
        @errors = Arkenstone::Validation::ValidationError.new
        validate_with_validators
        validate_with_custom_validators
      end

      private
      # Checks if the attribute is on the instance of the model. If the attribute is a string, checks if it's empty.
      # Example:
      #
      #     validates :name, presence: true
      #
      def validate_presence(attr, options)
        message = options[:message] || "can't be blank"
        test = options[:presence]
        method_not_defined = test != self.class.method_defined?(attr)
        if method_not_defined
          message
        else
          val = self.send(attr)
          value_is_nil = test == val.nil?
          if value_is_nil
            return message
          end
          value_is_string = val.class == String
          if value_is_string and val.empty?
            return message
          end
        end
      end

      def validate_empty(attr, options)
        message = options[:message] || "must not be empty"
        val = self.send(attr)
        return message if val.nil?
        return message if val.respond_to? :empty
        return message if val.empty?
      end

      # Checks if an attribute is the appropriate boolean value. 
      #
      # Example:
      #
      #     validates :accepts_terms, acceptance: true
      def validate_acceptance(attr, options)
        acceptance = options[:acceptance]
        message = options[:message] || "must be #{acceptance}"
        val = self.send(attr)
        message if val != acceptance
      end

      # Checks if an attribute is an instance of a specific type, or one of its descendents.
      #
      # Example:
      #
      #     validates :should_be_string, type: String
      #
      # That will check if `should_be_string` is a `String` or a subclass of `String`
      def validate_type(attr, options)
        type = options[:type]
        message = options[:message] || "must be type #{type}"
        val = self.send(attr)
        unless val.nil?
          message unless val.is_a? type
        end
      end

      # Checks if the attribute conforms with the provided regular expression.
      # Example:
      #
      #     validates :name, with: format: { with: /\d+/, message: "must be lowercase" }
      def validate_format(attr, options)
        val = send attr
        regex = options[:format][:with]
        if regex.match(val).nil?
          options[:format][:message]
        end
      end

      # Loops through all the custom validators created with `validate`.
      def validate_with_custom_validators
        unless self.class.custom_validators.nil?
          self.class.custom_validators.each do |custom_validator|
            send custom_validator
          end
        end
      end

      # Loops through the provided validators. A validator is passed when a validation method returns nil. All other values are treated as errors.
      def validate_with_validators
        return if self.class.fields_to_validate.nil?
        self.class.fields_to_validate.each do |attr, validators|
          validators.each do |validator_hash, arg|
            key = validator_hash.keys.first
            validation_method = "validate_#{key}"
            options = validator_hash[key]
            result = send validation_method, attr, options
            @errors.add(attr, result) unless result.nil?
          end
        end
      end      

    end

    module ClassMethods

      class << self
        def extended(base)
          base.fields_to_validate = {}
        end
      end

      attr_accessor :fields_to_validate, :custom_validators

      # Adds a custom validator method. Custom validators are responsible for adding errors to the `errors` hash.
      # Example:
      #
      #     class MyClass
      #       validate :special_case
      #
      #       def special_case
      #         if 1 == 2
      #           errors.add(:the_bad_property, "Error Message")
      #         end
      #       end
      #     end
      def validate(custom_validation_method)
        self.custom_validators = [] if self.custom_validators.nil?
        self.custom_validators << custom_validation_method
      end

      # Adds one of the provided validators to an attribute. Specify the validator in the `options` splat.
      # Example:
      #
      # class MyClass
      #   validates :name, presence: true
      #   validates :email, with: format: { with: /[a-z]+/, message: "must be valid email" }
      # end
      def validates(attr, *options)
        self.fields_to_validate = {} if self.fields_to_validate.nil?
        sym = attr.downcase.to_sym
        fields_for_attr = self.fields_to_validate[sym]
        if fields_for_attr.nil?
          fields_for_attr = []
          self.fields_to_validate[sym] = fields_for_attr
        end
        fields_for_attr << create_validator(Hash[*options])
      end

      ### Creates a validator hash from the options passed into a `validates` method.
      def create_validator(options_hash)
        key = options_hash.first[0]
        validator = {}
        validator[key] = options_hash
        validator
      end

    end

  end
end
