# rspec-let-each

this is just a proof of concept for an rspec helper idea I had.

a common dilemma I found when writing specs was
enumerating all edge cases is DRY and gives good coverage
but it requires too much block nesting/boiler plate.
Also, contexts written like this are not compatible with `let`s,
without some hackery.

e.g.
```
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
```
let(:x) { [foo, bar].sample }

it_behaves_like 'an example'
```

with this helper, we should be able to have the best of both worlds
 - same coverage as first example
 - compatible with `let` variables
 - same succintness as second example
```
let_each(:x, 2) { [foo, bar] }

it_behaves_like 'an example'
```

Using the `let_each` by itself lead to some awkward patterns when zipping expectations into the examples.
That's why I'm adding a chainable method `with`, intended for the corresponding expectations, or possibly actions.
now we might write
```
subject { test_method(x) }

let_each(:x, 2) { [foo, bar] }
  .with(:expected_x) { [foo_expect, bar_expect] }

it { is_expected.to eq(:expected_x) }
```
it can be continually chained, in case we need variables in tripples or quads too, why not.

note: this repo just has the helper and some specs. It's NOT a gem, currently, and I doubt I'll go that far.
However, anyone should feel free to fork the code and or comment/contribute.
