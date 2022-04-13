# frozen_string_literal: true

require_relative "lib/git/rails/changes/version"

Gem::Specification.new do |spec|
  spec.name = "git-rails-changes"
  spec.version = Git::Rails::Changes::VERSION
  spec.authors = ["Bart Agapinan"]
  spec.email = ["bart@sonic.net"]

  spec.summary = "Find recently changed files in your git working directory and some matching counterparts"
  spec.description = "git-rails-changes will find files that have changed between branches, that are staged, or modified but not staged. It can find matching rspec tests for rails files"
  spec.homepage = "https://github.com/viamin/git-rails-changes"
  spec.license = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.6.0")
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "optimist", "~> 3.0"
end
