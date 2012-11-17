require 'active_support/concern'

module Ripple

  class CriteriaError < StandardError; end

  # chainable Criteria methods such as :where, :lt, :lte, :gt, :gte, :between, 
  # with sort, :skip, :limit options
  class Criteria

    include Translation
    include Enumerable

    attr_accessor :selector, :klass, :options, :response, :cached, :total, :docs, :document_ids

    def initialize(klass)
      @selector, @klass, @options, @documents, @cached = "", klass, {}
      clear_cache
    end

    # Main criteria selector to search records
    #
    # === Example
    #
    #   Model.where(tags: "nerd", name: "Joe", something: 2)
    #
    # will append this selector:
    # "(tags:nerd AND name:Joe AND something:2)"
    def where(selector = nil)
      case selector
      when String
        add_restriction selector
      when Hash
        add_restriction to_lucene_pair(selector)
      end
      self
    end

    # Add an OR selector
    #
    # === Example
    #
    #   Product.or({name: "Pants"}, {name: "Shirt"})
    #
    # will append this selector:
    # "((name:Pants) OR (name:Shirt))"
    def or(*criterion)
      add_restriction do
        criterion.each do |crit|
          add_restriction(to_lucene_pair(crit, operator: "OR"), operator: "OR" )
        end
      end
      self
    end

    alias :any_of :or

    # Add an Range selector. Values in the passed hash can be either a Range or an Array.
    # of the passed hash has multiple elements, the condition will be AND.
    # The range is inclusive.
    #
    # === Example
    #
    #   Product.between(availibility: 1..3, price: [12, 20])
    #
    # will append this selector:
    # "((availibility:[1 TO 3] AND price:[12 TO 20]))"
    def between(*criterion)
      add_restriction do
        criterion.each do |crit|
          add_restriction(to_lucene_pair(crit, operator: "BETWEEN"))
        end
      end
      self
    end

    # Add a 'less or equal than' selector
    #
    # === Example
    #
    #   Product.lte(quantity: 10, ratings: 5)
    #
    # will append this selector:
    # "((quantity:[* TO 10] AND ratings:[* TO 5]))"
    def lte(*criterion)
      add_restriction do
        criterion.each do |crit|
          crit.each {|k,v| crit[k]=Array.wrap(v).unshift(10**20)}
          add_restriction(to_lucene_pair(crit, operator: "BETWEEN"))
        end
      end
      self
    end

    # Add a 'greater or equal than' selector
    #
    # === Example
    #
    #   Product.gte(quantity: 0, ratings: 5)
    #
    # will append this selector:
    # "((quantity:[0 TO *] AND ratings:[5 TO *]))"
    def gte(*criterion)
      add_restriction do
        criterion.each do |crit|
          crit.each {|k,v| crit[k]=Array.wrap(v).push(10**20)}
          add_restriction(to_lucene_pair(crit, operator: "BETWEEN"))
        end
      end
      self
    end

    # Add a 'less than' selector
    #
    # === Example
    #
    #   Product.lt(quantity: 10, ratings: 5)
    #
    # will append this selector:
    # "((quantity:{* TO 10} AND ratings:{* TO 5}))"
    def lt(*criterion)
      add_restriction do
        criterion.each do |crit|
          crit.each {|k,v| crit[k]=Array.wrap(v).unshift("*")}
          add_restriction(to_lucene_pair(crit, operator: "BETWEEN", exclusive: true))
        end
      end
      self
    end

    # Add a 'greater than' selector
    #
    # === Example
    #
    #   Product.gt(quantity: 0, ratings: 5)
    #
    # will append this selector:
    # "((quantity:{0 TO *} AND ratings:{5 TO *}))"
    def gt(*criterion)
      add_restriction do
        criterion.each do |crit|
          crit.each {|k,v| crit[k]=Array.wrap(v).push("*")}
          add_restriction(to_lucene_pair(crit, operator: "BETWEEN", exclusive: true))
        end
      end
      self
    end

    # Add sort options to criteria
    #
    # === Example
    #
    #   Product.between(availibility:[1,3]).sort(availibility: :asc, created_at: :desc)
    #
    # will append this sort option:
    # "availibility asc, created_at desc"
    def sort(sort_options)
      case sort_options
      when String
        add_sort_option sort_options
      when Hash
        sort_options.each {|k,v| add_sort_option "#{k} #{v.downcase}"}
      end
      self
    end

    alias :order_by :sort
    alias :order :sort

    # Add limit option to criteria. Useful for pagination. Default is 10.
    #
    # === Example
    #
    #   Product.between(availibility:[1,3]).limit(10)
    #
    # will limit the number of returned documetns to 10
    def limit(limit)
      clear_cache
      self.options[:rows] = limit
      self
    end

    alias :rows :limit

    # Add skip option to criteria. Useful for pagination. Default is 0.
    #
    # === Example
    #
    #   Product.between(availibility:[1,3]).skip(10)
    #
    def skip(skip)
      clear_cache
      self.options[:start] = skip
      self
    end

    alias :start :skip


    # Executes the search query
    def execute
      raise CriteriaError, t('empty_selector_error') if self.selector.blank?
      @response = @klass.search self.selector, self.options
    end

    # Returns the matched documents
    def documents
      if @cached
        @documents
      else
        parse_response
        @cached = true
        @documents = self.klass.find self.document_ids
      end
    end

    def each(&block)
      documents.each(&block)
    end

    # Total number of matching documents
    def total
      parse_response
      @total
    end

    # Array of matching document id's
    def document_ids
      parse_response
      @document_ids
    end

    def merge(criteria)
      add_restriction criteria.selector
      self.options.merge!(criteria.options)
      self
    end

    def method_missing(name, *args, &block)
      if klass.respond_to?(name)
        klass.send(:with_scope, self) do
          klass.send(name, *args, &block)
        end
      end
    end

  private

    def clear_cache
      @documents, @cached, @response, @total, @docs, @document_ids = [], false
    end

    def parse_response
      execute if @response.blank?
      self.total = @response["response"]["numFound"]
      self.docs = @response["response"]["docs"]
      self.document_ids = self.docs.map {|e| e["id"]}
    rescue
      clear_cache
      raise CriteriaError, t('failed_query')
    end

    def add_restriction(*args, &block)
      clear_cache
      options = args.extract_options!
      operator = options[:operator] || "AND"
      restriction = args.first
      separator = @selector.present? ? " #{operator} " : ""
      if block_given?
        @selector << "#{separator}("
        yield
        @selector << ")"
      else
        @selector << "#{separator unless @selector[-1] == '('}(#{restriction})"
      end
    end

    def add_sort_option(*args)
      clear_cache
      args.each do |s|
        if options[:sort].present?
          options[:sort] << ", #{s}"
        else
          options[:sort] = s
        end
      end
    end

    def to_lucene_pair(conditions, options = {})
      operator = options[:operator] || "AND"
      if operator == "BETWEEN"
        conditions.map do |k,v|
          case v
          when Range, Array
            "#{k}:#{options[:exclusive] ? '{' : '['}#{v.first} TO #{v.last}#{options[:exclusive] ? '}' : ']'}"
          when String
            "#{k}: #{v}"
          end
        end.join(" AND ")
      else
        conditions.map {|k,v| "#{k}:#{v}"}.join(" #{operator} ")
      end
    end
  end
end
