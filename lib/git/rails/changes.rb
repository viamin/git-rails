# frozen_string_literal: true

require "git/rails/changes/version"
require "optimist"

module Git
  module Rails
    module Changes
    class Error < StandardError; end

    class << self
      def main
        opts = Optimist.options do
          opt "all-files", "Don't exclude any files"
          opt "include-deleted", "Don't filter out deleted files"
          opt "code-only", "Filter out .yml, .json, and .md files"
          opt "spec-only", "Convert all paths to spec and remove non-spec files"
          opt "cached", "Only compare staged files (useful for pre-commit hooks)"
          opt "unstaged-only", "Only compare unstaged/uncommitted files"
          opt "branch",
            "Compare all changes with given branch (default main)",
            type: :string,
            default: "main"
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

        # gather all changes
        file_list = if opts["unstaged-only"]
          `git ls-files --modified --others #{"--exclude-standard" unless opts["all-files"]}`
        elsif opts["cached"]
          `git diff --name-status --cached #{"| grep -v '\''^D'\''" unless opts["include-deleted"]} | awk '{print $2}'`
        else
          `git diff --name-status #{opts["branch"]} #{"| grep -v '\''^D'\''" unless opts["include-deleted"]} | awk '{print $2}'`
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
        else
          command << `which echo`.strip
          file_list = [file_list.join("\n")]
        end

        if file_list.empty? && opts["replace-blank"]
          command << opts["replace-blank"]
        else
          command.concat(file_list)
        end

        command.compact!

        exec(*command)
      end

      private

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
    end
  end
end
end
