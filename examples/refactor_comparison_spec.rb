# try this example with `bundle exec rspec examples/refactor_comparison_spec.rb`
require_relative '../lib/let_each'

RSpec.describe 'refactoring example' do
  subject { x**2 }

  context 'without using let_each helper' do
    [1, 2, 3].zip([1, 4, 9]).each do |x, x_expected|
      context "with x=#{x} and x_expected=#{x_expected}" do
        let(:x) { x }
        let(:x_expected) { x_expected }

        it { is_expected.to be_a(Integer) }
        it { is_expected.to eq(x_expected) }
      end
    end
  end

  context 'using let_each helper' do
    let_each(:x, [1, 2, 3])
      .with(:x_expected, [1, 4, 9])

    it { is_expected.to be_a(Integer) }
    it { is_expected.to eq(x_expected) }
  end
end
