require 'active_support/concern'
require 'active_model/callbacks'
require 'active_model/naming'
require 'active_model/observing'
require 'ripple/conflict/document_hooks'
require 'ripple/document'
require 'ripple/callbacks'
require 'ripple/observable'

require 'ripple_searchable/version'
require 'ripple_searchable/searchable_observer'
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

I18n.load_path << File.join(File.dirname(__FILE__), "config", "locales", "en.yml")
