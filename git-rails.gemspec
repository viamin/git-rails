require_relative 'lib/git/rails/version'

Gem::Specification.new do |spec|
  spec.name          = 'git-rails'
  spec.version       = Git::Rails::VERSION
  spec.authors       = ['Bart Agapinan']
  spec.email         = ['bart@sonic.net']

  spec.summary       = 'Find recently changed files in your git working directory and some matching counterparts'
  spec.description   = 'git-rails will find files that have changed between branches, that are staged, or modified but not staged. It can find matching rspec tests for rails files'
  spec.homepage      = 'https://github.com/viamin/git-rails'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 2.3.0')
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage

  spec.add_runtime_dependency 'optimist', '~> 3.0'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
end
