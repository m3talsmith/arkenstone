module Arkenstone
  module Validation
    class << self
      def included(base)
        base.send :include, Arkenstone::Validation::InstanceMethods
        base.extend Arkenstone::Validation::ClassMethods
        base.fields_to_validate = {}
      end
    end    

    module InstanceMethods
      attr_accessor :errors

      def valid?
        validate
        @errors.count == 0
      end

      # TODO - allow passing in params to validate
      def validate
        @errors = Arkenstone::Validation::ValidationError.new
        validate_with_validators
        validate_with_custom_validators
      end

      private
      # TODO - account for custom messages 
      def validate_presence(attr, test, message = "can't be blank")
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

      def validate_format(attr, options)
        val = send attr
        regex = options[:with]
        if regex.match(val).nil?
          options[:message]
        end
      end

      def validate_with_custom_validators
        unless self.class.custom_validators.nil?
          self.class.custom_validators.each do |custom_validator|
            send custom_validator
          end
        end
      end

      def validate_with_validators
        self.class.fields_to_validate.each do |attr, validators|
          validators.each do |method, arg|
            validation_method = "validate_#{method}"
            result = send validation_method, attr, arg
            @errors.add(attr, result) unless result.nil?
          end
        end
      end      

    end

    module ClassMethods
      attr_accessor :fields_to_validate, :custom_validators

      def validate(custom_validation_method)
        self.custom_validators = [] if self.custom_validators.nil?
        self.custom_validators << custom_validation_method
      end

      def validates(attr, *options)
        self.fields_to_validate = {} if self.fields_to_validate.nil?
        sym = attr.downcase.to_sym
        fields_for_attr = self.fields_to_validate[sym]
        if fields_for_attr.nil?
          fields_for_attr = {} 
          self.fields_to_validate[sym] = fields_for_attr
        end
        fields_for_attr.merge! Hash[*options]
      end

    end

  end
end
