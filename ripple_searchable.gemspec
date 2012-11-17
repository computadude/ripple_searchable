# -*- encoding: utf-8 -*-
require File.expand_path('../lib/ripple_searchable/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Mark Ronai"]
  gem.email         = ["computadude@me.com"]
  gem.description   = %q{Mongoid / Active Record style query criteria and scoping for Ripple}
  gem.summary       = %q{Mongoid / Active Record style query criteria and scoping for Ripple}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "ripple_searchable"
  gem.require_paths = ["lib"]
  gem.version       = RippleSearchable::VERSION

  gem.add_dependency "activesupport", [">= 3.0.0", "< 3.3.0"]
  gem.add_dependency "activemodel", [">= 3.0.0", "< 3.3.0"]
  gem.add_dependency "ripple", ">=1.0.0.beta2"

  gem.add_development_dependency "rails", '3.2.8'
end
