# frozen_string_literal: true

# rubocop:disable Layout/LineLength
RSpec.describe Texter::Content do
  describe '.new' do
    describe 'raises an error if content missing' do
      subject { described_class.new }

      specify do
        expect { subject }.to raise_error ArgumentError, 'missing keyword: :text'
      end
    end

    describe 'sqashes whitespaces and sets lang' do
      subject { described_class.new(text: text) }

      describe 'english' do
        let(:text) do
          'After exploring colours  in my design, I realized it was really hard to pull off the    rainbow thing, so I opted for less.'
        end

        specify do
          expect(subject.text).not_to include '  '
          expect(subject.lang).to eql 'en'
        end
      end

      describe 'german' do
        let(:text) do
          'Nachdem ich die  Farben in meinem Design untersucht hatte, wurde mir klar, dass   es wirklich schwierig war, das Regenbogen-Ding durchzuziehen, also entschied ich mich für weniger.'
        end

        specify do
          expect(subject.text).not_to include '  '
          expect(subject.lang).to eql 'de'
        end
      end

      describe 'french' do
        let(:text) do
          "Après avoir exploré  les couleurs dans mon design, j'ai réalisé   qu'il était vraiment difficile de réussir l'arc-en-ciel, alors j'ai opté pour moins."
        end

        specify do
          expect(subject.text).not_to include '  '
          expect(subject.lang).to eql 'fr'
        end
      end

      describe 'spanish' do
        let(:text) do
          'Después de  explorar los colores en mi diseño, me di cuenta de   que era muy difícil sacar el arcoíris, así que opté por menos.'
        end

        specify do
          expect(subject.text).not_to include '  '
          expect(subject.lang).to eql 'es'
        end
      end

      describe 'italian' do
        let(:text) do
          "Dopo aver esplorato i colori  nel mio design, mi sono reso conto che   era davvero difficile realizzare l'arcobaleno, quindi ho optato per meno."
        end

        specify do
          expect(subject.text).not_to include '  '
          expect(subject.lang).to eql 'it'
        end
      end

      describe 'greek' do
        let(:text) do
          'Μετά την εξερεύνηση  των χρωμάτων στο σχέδιό μου, συνειδητοποίησα   ότι ήταν πολύ δύσκολο να βγάλω το ουράνιο τόξο, οπότε επέλεξα λιγότερα.'
        end

        specify do
          expect(subject.text).not_to include '  '
          expect(subject.lang).to eql 'el'
        end
      end

      describe 'russian' do
        let(:text) do
          'Изучив цвета  в своем дизайне, я понял, что добиться радуги очень   сложно, поэтому я выбрал меньшее.'
        end

        specify do
          expect(subject.text).not_to include '  '
          expect(subject.lang).to eql 'ru'
        end
      end

      describe 'chinese' do
        let(:text) do
          '在我的设计中探索了颜色之后， 我意识到很难实现彩虹的效果，  所以我选择了更少的颜色。'
        end

        specify do
          expect(subject.text).not_to include '  '
          expect(subject.lang).to eql 'zh'
        end
      end

      describe 'korean' do
        let(:text) do
          '내 디자인에서 색상을 탐색한  후 무지개를 구현하는 것이 정말 어렵다는 것을   깨달았기 때문에 덜 선택했습니다.'
        end

        specify do
          expect(subject.text).not_to include '  '
          expect(subject.lang).to eql 'ko'
        end
      end

      describe 'japanese' do
        let(:text) do
          'デザインで色を検討した後、 虹色のものをうまくやってのけるのは本当に難しいことに気づいたので、  色を減らすことにしました。'
        end

        specify do
          expect(subject.text).not_to include '  '
          expect(subject.lang).to eql 'ja'
        end
      end
    end
  end

  describe '#paragraphs' do
    subject { described_class.new(text: text).paragraphs }

    describe 'single' do
      let(:text) { 'foo bar' }

      specify do
        expect(subject).to match_array [text]
      end
    end

    describe 'multiple' do
      let(:text) { "foo \n\n bar \r\n baz \nok" }

      specify do
        expect(subject).to match_array %w[foo bar baz ok]
      end
    end
  end

  describe '#filtered' do
    subject { described_class.new(text: text).filtered }

    describe 'short' do
      let(:text) do
        'Technical roadmap: OpenSearch extensibility
          Wed, Apr 05, 2023 · Daniel (dB.) Doubrovkine
          The primary reason users choose OpenSearch is the wide range of use cases they can address with its features, such as search or log analytics. Thus, we aim to make the OpenSearch Project the preferred platform for builders by creating a vibrant and deeply integrated ecosystem of projects, features, content packs, integrations, and tools that can be found quickly, installed securely, combined to solve problems, and monetized by many participants.'
      end

      specify do
        expect { subject }.not_to raise_error
        expect(subject.length).to be < text.length
      end
    end

    describe 'long' do
      let(:text) do
        'Processes

         Speedup through multiple CPUs
         Speedup for blocking operations
         Variables are protected from change
         Extra memory used
         Child processes are killed when your main process is killed through Ctrl+c or kill -2
         Threads

         Speedup for blocking operations
         Variables can be shared/modified
         No extra memory used
         Ractors

         Ruby 3.0+ only
         Speedup for blocking operations
         No extra memory used
         Very fast to spawn
         Experimental and unstable
         start and finish hooks are called on main thread
         Variables must be passed in Parallel.map([1,2,3].map { |i| [i, ARGV, local_var] }, ...
         use Ractor.make_shareable to pass in global objects'
      end

      specify do
        expect { subject }.not_to raise_error
        expect(subject.length).to be < text.length
        expect(subject).to be_a String
      end
    end
  end

  describe 'issue: undefined method `include?`' do
    subject { described_class.new(text: text) }

    let(:text) do
      "#Overriding Wooden from Ripikazudetzuratzu!\n\n"
    end

    specify do
      expect(subject.text).to eql '#Overriding Wooden from Ripikazudetzuratzu!'
      expect(subject.lang).to eql 'eu'
    end
  end
end
# rubocop:enable Layout/LineLength
