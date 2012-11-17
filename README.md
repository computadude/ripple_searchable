# RippleSearchable

Mongoid / Active Record style query criteria DSL and Scoping for Ripple
using RIAK's solr search interface.

RippleSearchable adds chainable Criteria methods such as :where, :lt, :lte, :gt, :gte, :between
along with :sort, :skip, :limit options to your Ripple::Document models.

## Installation

Add this line to your application's Gemfile:

    gem 'ripple_searchable'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ripple_searchable

## Usage

### Criteria:

Any of the following criteria can be chained:

    :where, :lt, :lte, :gt, :gte, :between, with sort, :skip, :limit

=== Example:

```ruby
  Product.where(tags: "nerd", name: "joe", something: 2).or({can_sell:
1}, {can_sell: 3}).between(availibility: 1..3, price: [3,
12]).gte(quantity: 0, ratings: 5).sort(created_at, :desc).limit(5)
```

### Scoping

Mongoid / Active Record style named scopes:

=== Example:

```ruby
  class Product
    include Ripple::Document

    scope :active, where(active: true)
    scope :avail, ->(count){ where(quantity: count)}

  end
```

See [docs](http://rubydoc.info/github/computadude/ripple_searchable/master/frames) for method details.

TODO: Write better docs.

## Contributing

This gem is still under heavy development. Feel free to contribute.

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
