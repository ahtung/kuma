# encoding: utf-8

require 'spec_helper'

describe Kuma::Options, :isolated_environment do
  include FileHelper

  subject(:options) { described_class.new }

  before(:each) do
    $stdout = StringIO.new
    $stderr = StringIO.new
  end

  after(:each) do
    $stdout = STDOUT
    $stderr = STDERR
  end

  def abs(path)
    File.expand_path(path)
  end

  describe 'option' do
    describe '-h/--help' do
      it 'exits cleanly' do
        expect { options.parse ['-h'] }.to exit_with_code(0)
        expect { options.parse ['--help'] }.to exit_with_code(0)
      end

      it 'shows help text' do
        begin
          options.parse(['--help'])
        rescue SystemExit # rubocop:disable Lint/HandleExceptions
        end

        expected_help = <<-END
Usage: rubocop [options] [file1, file2, ...]
        --only [COP1,COP2,...]       Run only the given cop(s).
    -c, --config FILE                Specify configuration file.
        --auto-gen-config            Generate a configuration file acting as a
                                     TODO list.
        --force-exclusion            Force excluding files specified in the
                                     configuration `Exclude` even if they are
                                     explicitly passed as arguments.
    -f, --format FORMATTER           Choose an output formatter. This option
                                     can be specified multiple times to enable
                                     multiple formatters at the same time.
                                       [p]rogress (default)
                                       [s]imple
                                       [c]lang
                                       [d]isabled cops via inline comments
                                       [fu]ubar
                                       [e]macs
                                       [j]son
                                       [h]tml
                                       [fi]les
                                       [o]ffenses
                                       custom formatter class name
    -o, --out FILE                   Write output to a file instead of STDOUT.
                                     This option applies to the previously
                                     specified --format, or the default format
                                     if no format is specified.
    -r, --require FILE               Require Ruby file.
        --fail-level SEVERITY        Minimum severity for exit with error code.
        --show-cops [COP1,COP2,...]  Shows the given cops, or all cops by
                                     default, and their configurations for the
                                     current directory.
    -F, --fail-fast                  Inspect files in order of modification
                                     time and stop after the first file
                                     containing offenses.
    -d, --debug                      Display debug info.
    -D, --display-cop-names          Display cop names in offense messages.
    -R, --rails                      Run extra Rails cops.
    -l, --lint                       Run only lint cops.
    -a, --auto-correct               Auto-correct offenses.
    -n, --no-color                   Disable color output.
    -v, --version                    Display version.
    -V, --verbose-version            Display verbose version.
      END

        expect($stdout.string).to eq(expected_help)
      end

      it 'lists all builtin formatters' do
        begin
          options.parse(['--help'])
        rescue SystemExit # rubocop:disable Lint/HandleExceptions
        end

        option_sections = $stdout.string.lines.slice_before(/^\s*-/)

        format_section = option_sections.find do |lines|
          lines.first =~ /^\s*-f/
        end

        formatter_keys = format_section.reduce([]) do |keys, line|
          match = line.match(/^[ ]{39}(\[[a-z\]]+)/)
          next keys unless match
          keys << match.captures.first.gsub(/\[|\]/, '')
        end.sort

        expected_formatter_keys =
          RuboCop::Formatter::FormatterSet::BUILTIN_FORMATTERS_FOR_KEYS
          .keys.sort

        expect(formatter_keys).to eq(expected_formatter_keys)
      end
    end
  end
end