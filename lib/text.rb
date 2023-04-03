# frozen_string_literal: true

require 'cld'
require 'zeitwerk'

loader = Zeitwerk::Loader.for_gem
loader.setup

module Text
  class Error < StandardError; end
end
