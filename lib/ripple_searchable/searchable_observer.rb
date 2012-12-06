require 'active_support/concern'
require 'active_model/observing'
require 'ripple/document'
require 'ripple/observable'

module Ripple
  class SearchableObserver < ActiveModel::Observer

    def self.observed_classes
      @observed_classes ||= []
    end

    def after_save(m)
      Ripple.client.index(m.class.bucket_name, m.attributes.reject {|k,v| v.nil?}.merge(id: m.id))
    end
  end

end
