# frozen_string_literal: true

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
  end
end
