require 'ripple'
require 'ripple/translation'
require 'active_support/concern'
require 'ripple_searchable/version'
require 'ripple_searchable/searchable'
require 'ripple_searchable/criteria'
require 'ripple_searchable/loggable'
require 'ripple_searchable/scoping'

Ripple.class_eval do
  extend Ripple::Loggable
end

Ripple::Document.class_eval do
  include Ripple::Searchable
  include Ripple::Scoping
end
