module Arkenstone
  #
  # = Builder
  # Builds up the query from the DSL and returns a ruby hash.
  class QueryBuilder
  
    ### Initializes the @hash variable, which is used to build complex queries.
    def initialize
      @cache = {}
    end

    ### Main entry point for processing the DSL.
    def build(&block)
      result = instance_eval(&block)
      unless @cache.empty?
        result = flush.merge result
      end
      result.to_json
    end

    ### Finds the entries that have a value for a column in the provided +value_array+.
    def _in(value_array)
      { "$in" => value_array }
    end

    ### Finds entries who's values for a column are greater than the value provided.
    def _gt(val)
      { "$gt" => val }
    end

    ### Finds entries who's values for a column are greater than or equal to the value provided.
    def _gte(val)
      { "$gte" => val }
    end

    ### Finds entries who's values for a column are less than the value provided.
    def _lt(val)
      { "$lt" => val }
    end

    ### Finds entries who's values for a column are less than or equal to the value provided.
    def _lte(val)
      { "$lte" => val }
    end

    ### Finds entries that match *all* expressions in the value provided.
    def _and(*vals)
      evaluate_expression '$and', vals
    end

    ### Finds entries that match *any* expression in the value provided.
    def _or(*vals)
      evaluate_expression '$or', vals
    end

    ### Finds entries that do *not* match any expression in the value provided.
    def _not(*vals)
      evaluate_expression "$not", vals
    end

    ### Adds include statements for the database endpoint to parse.
    def _include(values)
      @cache = evaluate_expression "$include", values
    end

    private
    ### Evaluates an expression that takes multiple arguments. Used to walk through nested boolean statements.
    def evaluate_expression(bool_type, hash)
      { "#{bool_type}" => hash }
    end

    ### Spits out the stored expressions in the +hash+ and resets it.
    def flush
      result = @cache
      @cache = {}
      result
    end

  end
end
