# frozen_string_literal: true

module Arkenstone
  # QueryList extends Array to provide more customized options for Arkenstone documents.
  class QueryList < Array
    ### If an array is provided, concatenate it onto the instance so that it becomes one long array. Otherwise, push it on.
    def initialize(initial_value)
      if initial_value.class == Array
        concat initial_value
      else
        push initial_value
      end
    end

    # Assumes that every element is an Arkenstone::Document
    def to_json(options = nil)
      map(&:attributes).to_json(options)
    end
  end
end
