require 'spec_helper'

class ArkenstoneValidationTest < Test::Unit::TestCase
  def setup
  end

  def test_model_validate_presence
    eval %(
      class ArkenstoneTestFirstName
        include Arkenstone::Validation

        attr_accessor :first_name
        validates :first_name, presence: true
      end
    )
    model = ArkenstoneTestFirstName.new
    model.first_name = nil
    assert(model.valid? == false)
    model.first_name = "test"
    assert(model.valid?)
  end

  def test_model_validate_format
    eval %(
      class ArkenstoneTestLastName
        include Arkenstone::Validation

        attr_accessor :last_name
        validates :last_name, format: { with: /[a-z]+/, message: "must be lowercase" }      end
    )
    model = ArkenstoneTestLastName.new
    model.last_name = "ABC"
    assert(model.valid? == false)
    model.last_name = "abc"
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
end
