RSpec.describe 'refactoring example' do
  subject { x**2 }

  context 'without using let_each helper' do
    [1, 2, 3].each do |i|
      context "with x=#{i}" do
        let(:x) { i }

        it { is_expected.to be_a(Integer) }
      end
    end
  end

  context 'using let_each helper' do
    let_each(:x, [1, 2, 3])

    it { is_expected.to be_a(Integer) }
  end

  describe 'two variables' do
    subject { y + x**2 }

    context 'without using let_each helper' do
      [1, 2, 3].each do |i|
        context "with x=#{i}" do
          let(:x) { i }

          [1, 2, 3].each do |j|
            context "with y=#{j}" do
              let(:y) { j }

              it { is_expected.to be_a(Integer) }
            end
          end
        end
      end
    end

    context 'using let_each helper' do
      let_each(:x, [1, 2, 3])
      let_each(:y, [1, 2, 3])

      it { is_expected.to be_a(Integer) }
    end
  end
end
