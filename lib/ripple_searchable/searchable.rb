require 'active_support/concern'
require 'active_model/callbacks'
require 'active_model/observing'
require 'ripple/conflict/document_hooks'
require 'ripple/document'
require 'ripple/observable'

module Ripple
  module Searchable

    extend ActiveSupport::Concern

    included do
      Ripple::SearchableObserver.observed_classes << self
      begin
        Ripple::SearchableObserver.instance
      rescue Exception => e
        puts e.message
      end
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

      def index_after_save!
        Rails.logger.info "!!! creating after save"
        class_eval do
          after_save do |m|
            Rails.logger.info "!!! after save"
            Ripple.client.index(m.class.bucket_name, m.attributes.reject {|k,v| v.nil?}.merge(id: m.id))
          end
        end
      end

    end

  end
end
