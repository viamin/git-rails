#!/usr/bin/env ruby
# frozen_string_literal: true

# This script helps find changed files in your working directory
# List unstaged, staged (cached), and differences between your
# working branch and another one (by default, master)
#
# The --spec-only option will check a rails
# for its matching spec file (it assumes the spec file
# will be in the same directory structure, except under
# /spec/, and ends with _spec.rb)
#
# Use the --replace-blank option to prevent unwanted behavior when
# no results are returned. For example, feeding the output of this
# script to rspec is a great way to test only changed files
# but running rspec without any file paths will run the entire
# test suite! --replace-blank="<something here>" will ensure
# that doesn't happen. For rspec, we can use "--version" which will
# return the version number and exit successfully.
#
# --rspec-pre-commit is a nice shortcut to set all of the options needed
# to run specs in the git pre-commit hook. It sets --cached, --spec-only,
# and --replace-blank
#
# Symlink this to /usr/local/bin/git-rails for use in any other project!
# (ln -s $(pwd)/bin/git-rails /usr/local/bin/git-rails if you're in the
# root of the hunthelper git directory)

require "optimist"
opts = Optimist.options do
  opt "all-files", "Don't exclude any files"
  opt "include-deleted", "Don't filter out deleted files"
  opt "code-only", "Filter out .yml, .json, and .md files"
  opt "spec-only", "Convert all paths to spec and remove non-spec files"
  opt "cached", "Only compare staged files (useful for pre-commit hooks)"
  opt "unstaged-only", "Only compare unstaged/uncommitted files"
  opt "branch",
    "Compare all changes with given branch (default master)",
    type: :string,
    default: "master"
  opt "replace-blank",
    "Prevent blank output by sending alternate output",
    type: :string,
    default: "--version"
  opt "rspec-pre-commit", "Preset option for getting cached specs safely"
  opt "run-rspec", "Run rspec on the files found by the given options"
  opt "run-rspec-fail-fast", "Run rspec with the --fail-fast option"
  opt "run-rubocop", "Run rubocop on the files found by the given options"
  opt "run-rubocop-autocorrect", "Run rubocop with the --safe-auto-correct flag"
  opt "debug", "Print all command line options"
end

if opts["rspec-pre-commit"]
  opts["cached"] = true
  opts["spec-only"] = true
  opts["replace-blank"] = "--version"
end

puts opts if opts["debug"]

raise "Can't use both 'cached' (-c) and 'unstaged-only' (-u) flags" if opts["cached"] && opts["unstaged-only"]

def spec?(file_name)
  file_name.match?(/_spec.rb$/)
end

def spec_from_code(file_name)
  if /erb$|haml$|slim$/.match?(file_name)
    return file_name
        .gsub("app/", "spec/")
        .gsub(".haml", ".haml_spec.rb")
        .gsub(".erb", ".erb_spec.rb")
        .gsub(".slim", ".slim_spec.rb")
  end
  file_name = file_name.gsub(".rb", "_spec.rb")

  return file_name.gsub("lib/", "spec/lib/") if file_name.match?(%r{^/?lib/})

  file_name.gsub("app/", "spec/")
end

# gather all changes
file_list = if opts["unstaged-only"]
  `git ls-files --modified --others #{"--exclude-standard" unless opts["all-files"]}`
elsif opts["cached"]
  %x(git diff --name-status --cached #{
                "| grep -v '\''^D'\''" unless opts["include-deleted"]
              } | awk '{print $2}')
else
  %x(git diff --name-status #{opts["branch"]} #{
                "| grep -v '\''^D'\''" unless opts["include-deleted"]
              } | awk '{print $2}')
end
file_list = file_list.split("\n")

if opts["spec-only"]
  spec_array = file_list.map { |file| spec?(file) ? file : spec_from_code(file) }
  spec_array = spec_array.select { |file| file.match?(/_spec.rb$/) }
  spec_array = spec_array.map { |spec| File.exist?(File.expand_path(spec, `pwd`.strip)) ? spec : nil }
  file_list = spec_array.compact.uniq
end

file_list = file_list.reject { |file| /\.(yml|json|md)\Z/.match(file) } if opts["code-only"]

command = []
if opts["run-rspec"] || opts["run-rspec-fail-fast"]
  command << `which spring`.strip
  command << "rspec"
  command << "--fail-fast" if opts["run-rspec-fail-fast"]
elsif opts["run-rubocop"] || opts["run-rubocop-autocorrect"]
  command << `which rubocop`.strip
  command << "--safe-auto-correct" if opts["run-rubocop-autocorrect"]
# "#{`which rubocop`.strip} #{'--safe-auto-correct' if opts['rubocop-autocorrect']}"
else
  command << `which echo`.strip
  file_list = [file_list.join("\n")]
end

if file_list.empty? && opts["replace-blank"]
  # `#{run_cmd} #{opts['replace-blank']}`
  command << opts["replace-blank"]
else
  # exec run_cmd, **file_list
  command.concat(file_list)
end

command.compact!

exec(*command)
