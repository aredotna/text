# frozen_string_literal: true

module Text
  class Stopwords
    #
    # class methods
    #
    def self.dictionary
      Dir.glob(File.join(__dir__, 'locales', '*.csv')).each_with_object({}) do |file, memo|
        locale = file.split('/').last.split('.').first
        memo[locale] = File.read(file).split(',')
      end
    end

    #
    # instance methods
    #
    attr_accessor :stopwords

    # Public: initialize it
    # lang - a String, the ISO code of a language is required
    # list - an Array of words, replacing the default local list
    def initialize(lang:, _list: [])
      raise Text::Error, 'missing lang' if lang.to_s.empty?

      @stopwords = self.class.dictionary[lang]
    end
  end
end
