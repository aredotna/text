# frozen_string_literal: true

require_relative 'lib/texter/version'

Gem::Specification.new do |spec|
  spec.name = 'texter'
  spec.version = Texter::VERSION
  spec.authors = ['LeFnord']
  spec.email = ['pscholz.le@gmail.com']

  spec.summary = 'Basic Text processing.'
  spec.description = 'Basic Text processing to prepare a Text for further/other processing.
                      Includes (atm) Language detection, ...'
  spec.homepage = 'https://github.com/aredotna/texter'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor])
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Uncomment to register a new dependency of your gem
  spec.add_dependency 'activesupport', '>= 6', '< 8'
  spec.add_dependency 'cld'       # https://github.com/jtoy/cld
  spec.add_dependency 'zeitwerk'  # https://github.com/fxn/zeitwerk

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
  spec.metadata['rubygems_mfa_required'] = 'true'
end
