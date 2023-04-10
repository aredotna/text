# frozen_string_literal: true

module Texter
  class Content
    attr_accessor :text, :lang

    # Public: initialize it
    # text - the text to be precessed
    def initialize(text:)
      @text = prepare(text)
      @lang = detect_language
    end

    def filtered
      @filtered ||= Texter::Stopwords.new(lang: lang).filtered(text)
    end

    def parallel_filtered
      @parallel_filtered ||= begin
        count = paragraphs.size < 16 ? 2 : 4
        grouped_paragraphs = paragraphs.in_groups(count)
        memo = Parallel.map(grouped_paragraphs, in_threads: count) do |sections|
          Texter::Stopwords.new(lang: lang).filtered(sections.join("\n\n"))
        end
        memo.flatten.join("\n\n")
      end
    end

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
