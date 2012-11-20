require 'active_support/concern'

module Ripple
  module Searchable

    extend ActiveSupport::Concern

    included do
      extend ClassMethods
    end

    unless method_defined? :id
      define_method :id do
        self.key
      end
    end

    module ClassMethods

      attr_accessor :criteria

      delegate :where, :or, :any_of, :gte, :lte, :gt, :lt, :between, :sort, to: :criteria

      # Performs a search via the Solr interface.
      def search(*args)
        Ripple.client.search(self.bucket_name, *args)
      end

      def criteria
        @criteria = default_scoping.try(:call) || Criteria.new(self)
      end
    end

  end
end
