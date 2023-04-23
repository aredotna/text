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
      @filtered ||= Texter::Stopwords.new(lang: @lang, text: @text).filtered
    end

    def paragraphs
      @paragraphs ||= text.gsub(/\R{2,}/, "\n").split(/\R/).map(&:strip)
    end

    private

    def prepare(text)
      text.gsub(/([[:blank:][:punct:]]){2,}(\d+)$/, ' ')
          .gsub(/([[:blank:][:punct:]]){2,}/, ' ')
          .gsub(/[[:blank:]]{2,}/, ' ')
          .gsub(/([[:punct:]]){2,}/, ' ').strip
    end

    def detect_language
      detected = CLD.detect_language(text)
      detected[:reliable] ? detected[:code] : 'en'
    end
  end
end
