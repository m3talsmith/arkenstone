require 'spec_helper'

class ArkenstoneValidationTest < Test::Unit::TestCase
  def setup
    eval %(
      class ArkenstoneTestFirstName
        include Arkenstone::Validation

        attr_accessor :first_name
        validates :first_name, presence: true
      end
    )
  end

  def test_model_validate_presence
    model = ArkenstoneTestFirstName.new
    model.first_name = nil
    assert(model.valid? == false)
    model.first_name = "test"
    assert(model.valid?)
  end

  def test_model_validate_presence_empty_string
    model = ArkenstoneTestFirstName.new
    model.first_name = ""
    assert(model.valid? == false)
  end

  def test_model_validate_empty_array
    eval %(
      class ArkenstoneTestEmpty
        include Arkenstone::Validation

        attr_accessor :values
        validates :values, empty: false
      end
    )
    model = ArkenstoneTestEmpty.new
    assert_equal false, model.valid?
    model.values = []
    assert_equal false, model.valid?
    model.values = ['hi']
    assert_equal true, model.valid?
  end

  def test_model_validate_format
    eval %(
      class ArkenstoneTestLastName
        include Arkenstone::Validation

        attr_accessor :last_name
        validates :last_name, format: { with: /[a-z]+/, message: "must be lowercase" }      
      end
    )
    model = ArkenstoneTestLastName.new
    model.last_name = "ABC"
    assert(model.valid? == false)
    model.last_name = "abc"
    assert(model.valid?)
  end

  def test_model_validate_true_value
    eval %(
      class ArkenstoneTestBool
        include Arkenstone::Validation

        attr_accessor :accepts_tandcs
        validates :accepts_tandcs, acceptance: true
      end
    )
    model = ArkenstoneTestBool.new
    assert(model.valid? == false)
    assert(model.errors[:accepts_tandcs] == ['must be true'])
  end

  def test_model_validates_type
    eval %(
      class ArkenstoneTestType
        include Arkenstone::Validation

        attr_accessor :should_be_string
        validates :should_be_string, type: String
      end
    )

    model = ArkenstoneTestType.new
    model.should_be_string = "hi"
    assert(model.valid?)
    model.should_be_string = 100
    assert(model.valid? == false)

    eval %(
      class BaseThing
      end

      class ChildThing < BaseThing
      end

      class InheritanceTestType
        include Arkenstone::Validation

        attr_accessor :should_be_base
        validates :should_be_base, type: BaseThing
      end
    )
    model = InheritanceTestType.new
    model.should_be_base = ChildThing.new
    assert(model.valid?)
  end
  
  def test_model_validates_confirmation
    eval %(
      class ArkenstoneTestConfirmation
        include Arkenstone::Document
        include Arkenstone::Validation
        
        attributes :email
        attr_accessor :email_confirmation
        
        validates :email, confirmation: true
      end
    )
    
    model = ArkenstoneTestConfirmation.new
    model.email = 'test@example.com'
    
    assert(!model.valid?)
    assert_equal(["confirmation does not match email"], model.errors[:email])
    
    model.email_confirmation = model.email
    
    assert(model.valid?)
  end

  def test_model_custom_validator
    eval %(
      class ArkenstoneTestCustom
        include Arkenstone::Validation

        attr_accessor :number
        validate :numberwang

        def numberwang # http://www.youtube.com/watch?v=qjOZtWZ56lc
          errors.add(:number, "That's numberwang!") unless [3, 19, 333].include? @number
        end
      end
    )
    model = ArkenstoneTestCustom.new
    model.number = 100
    assert(model.valid? == false)
    model.number = 19
    assert(model.valid?)
  end

  def test_validation_errors
    model = ArkenstoneTestFirstName.new
    model.first_name = nil
    model.valid?
    assert(model.errors.nil? == false)
    assert(model.errors[:first_name] == ["can't be blank"])
  end

  def test_validation_with_nil_fields_to_validate
    eval %(
      class ArkenstoneTestValidator
        include Arkenstone::Validation
        include Arkenstone::Document

        attributes :id
      end

      class ArkenstoneChildValidator < ArkenstoneTestValidator
      end
    )
    model = ArkenstoneChildValidator.new
    assert(model.valid?)
  end

  def test_custom_messages
    eval %(
      class ArkenstoneCustomMessage
        include Arkenstone::Validation

        attr_accessor :name

        validates :name, presence: true, message: "Test Message"
      end
    )

    model = ArkenstoneCustomMessage.new
    model.name = nil
    assert(model.valid? == false)
    assert(model.errors[:name] == ['Test Message'])
  end

end
