
RSpec.describe 'let_each helper' do
  context 'with x' do
    # lazy signature
    let_each(:x, 2) { [mock_thing.x, 6] }
    # eager signature
    let_each(:y, [33, 44, 55])
    let(:mock_thing) { double('mock_thing', x: lazy_x) }
    let(:lazy_x) { 4 }

    shared_examples 'a shared example' do
      it 'true' do
        expect(true).to be(true)
      end
    end

    shared_examples 'an example with a let_each' do
      let_each(:a, 2) { [1, 2] }

      it 'a is an option from the block result' do
        expect(a).to be_in([1, 2])
      end
    end

    it 'x is an option from the block result' do
      expect(x).to be_in([4, 6])
    end

    it 'y is an option from the array argument' do
      expect(y).to be_in([33, 44, 55])
    end

    it_behaves_like 'an example with a let_each'

    context 'when changing an upstream let' do
      let(:lazy_x) { 12 }

      it 'updates x per the redefined let' do
        expect(x).to be_in([12, 6])
      end

      it_behaves_like 'a shared example'
    end

    context 'when nesting more let_each' do
      let_each(:z, 2) { [77, 88] }

      it 'sets z to one of the block results' do
        expect(z).to be_in([77, 88])
      end
    end
  end

  context 'without x' do
    it 'does not have an x' do
      expect { x }.to raise_error(NameError)
    end
  end
end
