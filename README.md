[![Gem Version](https://badge.fury.io/rb/let_each.svg)](https://badge.fury.io/rb/let_each)
![Tests](https://github.com/Alogsdon/rspec-let-each/actions/workflows/test.yml/badge.svg)
# LetEach
(rspec-let-each)

`let_each` is an ergonomic RSpec helper that spawns context blocks with corresponding `let`s for each value in an array

a common dilemma I found when writing specs was
enumerating all edge cases is DRY and gives good coverage
but it requires too much block nesting/boiler plate.
Also, contexts written like this are not compatible with `let`s,
without some hackery.

e.g.
```ruby
[foo,bar].each do |x_local|
  context "with x=#{x_local}" do
    let(:x) { x_local }

    it_behaves_like 'an example'
  end
end
```

alternatively, let + sample is succint
but it gives flakey coverage
e.g.
```ruby
let(:x) { [foo, bar].sample }

it_behaves_like 'an example'
```

with this helper, we should be able to have the best of both worlds
 - same coverage as first example
 - compatible with `let` variables
 - same succintness as second example
```ruby
let_each(:x, 2) { [foo, bar] }

it_behaves_like 'an example'
```

Using the `let_each` by itself can lead to some awkward patterns when zipping expectations into the examples.
That's why I added a chainable method `with`, intended for the corresponding expectations, or possibly actions.
(The length of all chained `with`s is assumed to be the same as the parent `let_each`)
now we might write
```ruby
subject { test_method(x) }

let_each(:x, 2) { [foo, bar] }
  .with(:expected_x) { [foo_expect, bar_expect] }

it { is_expected.to eq(expected_x) }
```
it can be continually chained, in case we need variables in tripples or quads too, why not.

## Failure messaging

Generated contexts try to tell you *which* value blew up, so you don't have to count into the array.

When the values are known at load time (eager array, or explicit `labels:`), they go straight into the context name:

```ruby
let_each(:x, [10, 2]).with(:y, [101, 5])
# sandbox when x[0] = 10, y = 101
# sandbox when x[1] = 2, y = 5

let_each(:x, 2, labels: %w[empty full]) { [[], [1]] }
# sandbox when x[0] = empty
# sandbox when x[1] = full
```

Lazy blocks can't be evaluated until the example runs, so those values are resolved and appended to the description of **failing** examples only:

```
1) my spec when x[1] is expected to eq 51 [x = 7, y = 51]
   Failure/Error: it { is_expected.to eq(y) }
```

Turn the appending off with `LetEach.annotate_failures = false`.

## Installation

Add this line to your application's `Gemfile` typically inside the `:test` group:

```ruby
group :test do
  gem 'let_each'
end
```

## Setup

`let_each` is configured to automatically mix into RSpec's example groups when loaded.
In some projects, the `lib` folder is automatically loaded. If not, just add a require for `let_each` in your test setup.
```ruby
# spec/spec_helper.rb
require 'let_each'
```
You can immediately start using let_each inside your describe or context blocks.


### Verifying Installation
You can verify that the helper is loaded correctly by running a simple test:

```ruby
RSpec.describe "LetEach Integration" do
  let_each(:val, [1, 2])
  
  it "works" do
    expect([1, 2]).to include(val)
  end
end
```

## Compatibility

`let_each` is tested against and supports:
- **Ruby:** 2.7, 3.0, 3.1, 3.2, 3.3, 3.4
- **RSpec:** 3.0 and newer

## License
MIT
