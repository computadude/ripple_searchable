require 'active_support/concern'

module Ripple
  module Scoping
    extend ActiveSupport::Concern

    included do
      class_attribute :default_scoping
      class_attribute :scopes
      self.scopes = {}
    end

    module ClassMethods


      # Create a scope that can be accessed from the class level or chained to
      # criteria by the provided name.
      #
      # === Example
      #
      #   class Product
      #     include Ripple::Document
      #
      #     scope :active, where(active: true)
      #     scope :avail, ->(count){ where(quantity: count)}
      #   end
      #
      #   Product.active.where(name: "peter")
      #
      # sets the selector to:
      # "((active:true)) AND (name:peter)"
      def scope(name, value, &block)
        name = name.to_sym
        valid_scope_name?(name)
        scopes[name] = {
          scope: strip_default_scope(value),
          extension: Module.new(&block)
        }
        define_scope_method(name)
      end

      def default_scope(value)
        self.default_scoping = if default_scoping
          ->{ default_scoping.call.merge(value.to_proc.call) } unless default_scoping.call == value
        else
          value.to_proc
        end
      end

      def scope_stack
        Thread.current[:"#{self.bucket_name}_scope_stack"] ||= []
      end

      def with_default_scope
        default_scoping.try(:call) || without_default_scope
      end

      def without_default_scope
        Thread.current[:"#{self.bucket_name}_without_default_scope"] = true
        scope_stack.last || Criteria.new(self)
      end

      def without_default_scope?
        Thread.current[:"#{self.bucket_name}_without_default_scope"]
      end

      def with_scope(criteria)
        scope_stack.push(criteria)
        begin
          yield criteria
        ensure
          scope_stack.pop
        end
      end

    protected

      def valid_scope_name?(name)
        if Ripple.logger && respond_to?(name, true)
          Ripple.logger.warn "Creating scope :#{name}. " \
                      "Overwriting existing method #{self.name}.#{name}."
        end
      end

      def define_scope_method(name)
        (class << self; self; end).class_eval <<-SCOPE
          def #{name}(*args)
            scoping = scopes[:#{name}]
            scope, extension = scoping[:scope].(*args), scoping[:extension]
            criteria = with_default_scope.merge(scope)
            criteria.extend(extension)
            criteria
          end
        SCOPE
      end

      def strip_default_scope(value)
        if value.is_a?(Criteria)
          value.to_proc
        else
          value
        end
      end

    end
  end
end
