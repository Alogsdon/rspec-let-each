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

