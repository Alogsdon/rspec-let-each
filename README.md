# rspec-expect-each

this is just a proof of concept for an rspec helper idea I had.

a common dilemma I found when writing specs was
enumerating all edge cases is DRY and gives good coverage
but it requires too much block nesting
also, I find it harder to follow
e.g.

[foo,bar].each do |x|
  context "with x=#{x}" do
    it { is_expected.to be_truthy }
  end
end

alternatively, let + sample is succint
but it gives flakey coverage
e.g.

let(:x) { [foo, bar].sample }
it { is_expected.to be_truthy }
