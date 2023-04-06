# frozen_string_literal: true

# rubocop:disable Layout/LineLength
RSpec.describe Text::Stopwords do
  describe '.dictionary' do
    subject { described_class.dictionary }

    specify do
      expect(subject).to be_a Hash
      expect(subject.keys).to include 'en', 'de', 'fr', 'es', 'it', 'el', 'ru', 'zh', 'ko', 'ja'
      expect(subject.values).to all be_a Array
    end
  end

  describe '.new' do
    describe 'lang missing' do
      specify do
        expect { described_class.new(lang: '') }.to raise_error Text::Error, 'missing lang'
      end

      specify do
        expect { described_class.new(lang: nil) }.to raise_error Text::Error, 'missing lang'
      end
    end

    describe 'language given -> load list for it' do
      subject { described_class.new(lang: 'en') }

      specify do
        expect(subject.stopwords).to be_a Array
        expect(subject.stopwords).not_to be_empty
        expect(subject.stopwords).to include 'i', 'me', 'my'
      end
    end

    describe 'list given -> use this instead lang list' do
      subject { described_class.new(lang: 'en', list: ['many']) }

      specify do
        expect(subject.stopwords).to be_a Array
        expect(subject.stopwords).not_to be_empty
        expect(subject.stopwords).to match_array ['many']
      end
    end
  end

  describe '#filter -> removes punctation and stopwords' do
    subject { described_class.new(lang: lang).filtered(text) }

    describe 'english' do
      let(:lang) { 'en' }
      let(:text) do
        'After exploring Colours in my Design, I realized it was really hard to pull off the rainbow thing, so I opted for less.'
      end
      let(:expected) do
        'exploring Colours Design realized hard pull rainbow thing opted less'
      end
      specify do
        expect(subject).not_to match(/[[:punct:]]/)
        expect(subject).to eql expected
      end
    end

    describe 'french' do
      let(:lang) { 'fr' }
      let(:text) do
        "Après avoir exploré les couleurs dans mon design, j'ai réalisé qu'il était vraiment difficile de réussir l'arc-en-ciel, alors j'ai opté pour moins."
      end
      let(:expected) do
        "Après avoir exploré couleurs design j'ai réalisé qu'il vraiment difficile réussir l'arc-en-ciel alors j'ai opté moins"
      end
      specify do
        expect(subject).to eql expected
      end
    end

    describe 'korean' do
      let(:lang) { 'ko' }
      let(:text) do
        '내 디자인에서 색상을 탐색한 후 무지개를 구현하는 것이 정말 어렵다는 것을 깨달았기 때문에 덜 선택했습니다.'
      end

      let(:expected) do
        '내 디자인에서 색상을 탐색한 후 무지개를 구현하는 것이 정말 어렵다는 것을 깨달았기 덜 선택했습니다'
      end
      specify do
        p subject
        expect(subject).to eql expected
      end
    end
  end
end
# rubocop:enable Layout/LineLength
