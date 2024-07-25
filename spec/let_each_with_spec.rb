
RSpec.describe 'let_each_with helper' do
  subject { x**2 + 1 }

  context 'with eager signature' do
    let_each(:x, [10, 2, 5])
      .with(:y, [101, 5, 26])
    let(:lazy_y) { y + 1 }
    let(:lazy_x) { x + 1 }

    it { is_expected.to eq(y) }

    it 'downstream let may depend on either' do
      expect(lazy_x).to eq(x + 1)
      expect(lazy_y).to eq(y + 1)
    end
  end

  context 'with lazy signature' do
    let_each(:x, 4) { [1, 0, lazy_x, 2] }
      .with(:y) { [2, 1, 50, lazy_y] }

    let(:lazy_x) { 7 }
    let(:lazy_y) { 5 }

    it { is_expected.to eq(y) }

    it 'both may depend on upstream let' do
    end
  end

  context 'tripple chaining' do
    let_each(:x, 2) { [1, 2] }
      .with(:y) { [10, 20] }
      .with(:z) { [11, 22] }

    it 'they zip together' do
      expect(y).to eq(x * 10)
      expect(z).to eq(y + x)
      expect(z).to eq(x * 11)
    end
  end
end
