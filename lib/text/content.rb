# frozen_string_literal: true

module Text
  class Content
    attr_accessor :text, :lang

    # Public: initialize it
    # text - the text to be precessed
    def initialize(text:)
      @text = prepare(text)
      @lang = detect_language
    end

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
    def filtered
      @filtered ||= begin
        memo = {}
        count = paragraphs.size < 8 ? 2 : 8
        grouped_paragraphs = paragraphs.in_groups(count)
                                       .each_with_index
                                       .with_object([]) { |(c, index), m| m << { index => c } }

        Parallel.each(grouped_paragraphs, in_threads: count) do |sections|
          memo[sections.keys.first] = []
          sections.values.first.compact.each do |section|
            memo[sections.keys.first] << Text::Stopwords.new(lang: lang).filtered(section)
          end
        end
        memo.values.flatten.join("\n")
      end
    end
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/AbcSize

    def paragraphs
      @paragraphs ||= text.gsub(/\R{2,}/, "\n").split(/\R/).map(&:strip)
    end

    private

    def prepare(text)
      text.gsub(/[[:blank:]]{2,}/, ' ')
    end

    def detect_language
      detected = CLD.detect_language(text)
      detected[:reliable] ? detected[:code] : 'en'
    end
  end
end
