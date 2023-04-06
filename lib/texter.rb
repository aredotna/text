# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext'
require 'cld'
require 'parallel'
require 'zeitwerk'

loader = Zeitwerk::Loader.for_gem
loader.setup

module Texter
  class Error < StandardError; end
end
