# frozen_string_literal: true

RSpec.describe 'let_each failure messaging' do
  # runs a spec file in a fresh, isolated RSpec world so we can assert on descriptions
  def run_examples(&group_block)
    group = RSpec.describe('sandbox', &group_block)
    group.run(RSpec::Core::NullReporter)
    group_descriptions(group)
  end

  def group_descriptions(group)
    group.examples.map { |example| example.metadata[:full_description] } +
      group.children.flat_map { |child| group_descriptions(child) }
  end

  context 'with an eager array' do
    it 'names each context with the value' do
      descriptions = run_examples do
        let_each(:x, [33, 'a b'])

        it('passes') { expect(x).to be_truthy }
      end

      expect(descriptions).to contain_exactly(
        'sandbox when x[0] = 33 passes',
        'sandbox when x[1] = "a b" passes'
      )
    end

    it 'truncates long values' do
      descriptions = run_examples do
        let_each(:x, ['y' * 100])

        it('passes') { expect(x).to be_truthy }
      end

      expect(descriptions.first).to eq(%(sandbox when x[0] = "#{'y' * 36}... passes))
    end

    it 'names eager `with` values too' do
      descriptions = run_examples do
        let_each(:x, [1, 2]).with(:y, [10, 20])

        it('passes') { expect(x).to be_truthy }
      end

      expect(descriptions).to contain_exactly(
        'sandbox when x[0] = 1, y = 10 passes',
        'sandbox when x[1] = 2, y = 20 passes'
      )
    end
  end

  context 'with labels' do
    it 'names each context with the label' do
      descriptions = run_examples do
        let_each(:x, 2, labels: %w[empty full]) { [[], [1]] }
          .with(:y, labels: %w[none some]) { [0, 1] }

        it('passes') { expect(x).to be_truthy }
      end

      expect(descriptions).to contain_exactly(
        'sandbox when x[0] = empty, y = none passes',
        'sandbox when x[1] = full, y = some passes'
      )
    end

    it 'rejects a label list of the wrong length' do
      expect do
        run_examples { let_each(:x, 2, labels: %w[only_one]) { [1, 2] } }
      end.to raise_error(/labels must have the same length/)
    end

    it 'rejects a chained label list of the wrong length' do
      expect do
        run_examples { let_each(:x, 2) { [1, 2] }.with(:y, labels: %w[a b c]) { [1, 2] } }
      end.to raise_error(/labels must have the same length/)
    end
  end

  context 'with a lazy block' do
    it 'appends the resolved values to failing examples only' do
      descriptions = run_examples do
        let_each(:x, 2) { [lazy_x, 2] }.with(:y) { [10, 20] }
        let(:lazy_x) { 1 }

        it('fails when x is odd') { expect(x).to be_even }
      end

      expect(descriptions).to contain_exactly(
        'sandbox when x[0] fails when x is odd [x = 1, y = 10]',
        'sandbox when x[1] fails when x is odd'
      )
    end

    it 'does not annotate values that are already in the description' do
      descriptions = run_examples do
        let_each(:x, [1]).with(:y) { [10] }

        it('fails') { expect(x).to be_even }
      end

      expect(descriptions).to contain_exactly('sandbox when x[0] = 1 fails [y = 10]')
    end

    it 'nests and reports nested let_eaches in declaration order' do
      descriptions = run_examples do
        let_each(:x, 1) { [1] }
        context 'nested' do
          let_each(:y, 1) { [2] }

          it('fails') { expect(x).to be_even }
        end
      end

      expect(descriptions).to contain_exactly('sandbox nested when x[0] when y[0] fails [x = 1, y = 2]')
    end

    it 'nests and reports sibling let_eaches in declaration order' do
      descriptions = run_examples do
        let_each(:x, 1) { [1] }
        let_each(:y, 1) { [2] }

        it('fails') { expect(x).to be_even }
      end

      expect(descriptions).to contain_exactly('sandbox when x[0] when y[0] fails [x = 1, y = 2]')
    end

    it 'does not blow up when a value raises' do
      descriptions = run_examples do
        let_each(:x, 1) { [raise('boom')] }

        it('fails') { expect(x).to be_even }
      end

      expect(descriptions).to contain_exactly('sandbox when x[0] fails [x = <RuntimeError>]')
    end

    it 'can be disabled' do
      LetEach.annotate_failures = false
      descriptions = run_examples do
        let_each(:x, 1) { [1] }

        it('fails') { expect(x).to be_even }
      end

      expect(descriptions).to contain_exactly('sandbox when x[0] fails')
    ensure
      LetEach.annotate_failures = true
    end
  end
end
