# frozen_string_literal: true

module Text
  class Content
    attr_accessor :content, :lang

    def initialize(content:)
      @content = content

      detect_language
    end

    def detect_language
      detected = CLD.detect_language(content)
      @lang = detected[:reliable] ? detected[:code] : 'en'
    end
  end
end
