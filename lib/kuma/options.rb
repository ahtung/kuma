# encoding: utf-8

require 'optparse'

module Kuma
  # This module contains help texts for command line options.
  module OptionsHelp
    TEXT = {
      only:              'Run only the given cop(s).',
      require:           'Require Ruby file.',
      config:            'Specify configuration file.',
      auto_gen_config:  ['Generate a configuration file acting as a',
                         'TODO list.'],
      force_exclusion:  ['Force excluding files specified in the',
                         'configuration `Exclude` even if they are',
                         'explicitly passed as arguments.'],
      format:           ['Choose an output formatter. This option',
                         'can be specified multiple times to enable',
                         'multiple formatters at the same time.',
                         '  [p]rogress (default)',
                         '  [s]imple',
                         '  [c]lang',
                         '  [d]isabled cops via inline comments',
                         '  [fu]ubar',
                         '  [e]macs',
                         '  [j]son',
                         '  [h]tml',
                         '  [fi]les',
                         '  [o]ffenses',
                         '  custom formatter class name'],
      out:              ['Write output to a file instead of STDOUT.',
                         'This option applies to the previously',
                         'specified --format, or the default format',
                         'if no format is specified.'],
      fail_level:        'Minimum severity for exit with error code.',
      show_cops:        ['Shows the given cops, or all cops by',
                         'default, and their configurations for the',
                         'current directory.'],
      fail_fast:        ['Inspect files in order of modification',
                         'time and stop after the first file',
                         'containing offenses.'],
      debug:             'Display debug info.',
      display_cop_names: 'Display cop names in offense messages.',
      rails:             'Run extra Rails cops.',
      lint:              'Run only lint cops.',
      auto_correct:      'Auto-correct offenses.',
      no_color:          'Disable color output.',
      version:           'Display version.',
      verbose_version:   'Display verbose version.'
    }
  end

  # This class handles command line options.
  class Options
    DEFAULT_FORMATTER = 'progress'
    EXITING_OPTIONS = [:version, :verbose_version, :show_cops]

    def initialize
      @options = {}
    end

    def parse(args)
      ignore_dropped_options(args)
      convert_deprecated_options(args)

      OptionParser.new do |opts|
        opts.banner = 'Usage: rubocop [options] [file1, file2, ...]'

        option(opts, '--only [COP1,COP2,...]') do |list|
          @options[:only] = list.split(',').map do |c|
            Cop::Cop.qualified_cop_name(c, '--only option')
          end
        end

        add_configuration_options(opts, args)
        add_formatting_options(opts)

        option(opts, '-r', '--require FILE') { |f| require f }

        add_flags_with_optional_args(opts)
        add_boolean_flags(opts)
      end.parse!(args)

      if (incompat = @options.keys & EXITING_OPTIONS).size > 1
        fail ArgumentError, "Incompatible cli options: #{incompat.inspect}"
      end

      [@options, args]
    end

    private

    def add_configuration_options(opts, args)
      option(opts, '-c', '--config FILE')

      option(opts, '--auto-gen-config') do
        validate_auto_gen_config_option(args)
        @options[:formatters] = [[DEFAULT_FORMATTER],
                                 [Formatter::DisabledConfigFormatter,
                                  ConfigLoader::AUTO_GENERATED_FILE]]
      end

      option(opts, '--force-exclusion')
    end

    def add_formatting_options(opts)
      option(opts, '-f', '--format FORMATTER') do |key|
        @options[:formatters] ||= []
        @options[:formatters] << [key]
      end

      option(opts, '-o', '--out FILE') do |path|
        @options[:formatters] ||= [[DEFAULT_FORMATTER]]
        @options[:formatters].last << path
      end
    end

    def add_flags_with_optional_args(opts)
      option(opts, '--show-cops [COP1,COP2,...]') do |list|
        @options[:show_cops] = list.nil? ? [] : list.split(',')
      end
    end

    def add_boolean_flags(opts)
      option(opts, '-F', '--fail-fast')
      option(opts, '-d', '--debug')
      option(opts, '-D', '--display-cop-names')
      option(opts, '-R', '--rails')
      option(opts, '-l', '--lint')
      option(opts, '-a', '--auto-correct')

      @options[:color] = true
      option(opts, '-n', '--no-color') { @options[:color] = false }

      option(opts, '-v', '--version')
      option(opts, '-V', '--verbose-version')
    end

    # Sets a value in the @options hash, based on the given long option and its
    # value, in addition to calling the block if a block is given.
    def option(opts, *args)
      long_opt_symbol = long_opt_symbol(args)
      args += Array(OptionsHelp::TEXT[long_opt_symbol])
      opts.on(*args) do |arg|
        @options[long_opt_symbol] = arg
        yield arg if block_given?
      end
    end

    # Finds the option in `args` starting with -- and converts it to a symbol,
    # e.g. [..., '--auto-correct', ...] to :auto_correct.
    def long_opt_symbol(args)
      long_opt = args.find { |arg| arg.start_with?('--') }
      long_opt[2..-1].sub(/ .*/, '').gsub(/-/, '_').to_sym
    end

    def ignore_dropped_options(args)
      # Currently we don't make -s/--silent option raise error
      # since those are mostly used by external tools.
      rejected = args.reject! { |a| %w(-s --silent).include?(a) }
      return unless rejected

      warn '-s/--silent options is dropped. ' \
           '`emacs` and `files` formatters no longer display summary.'
    end

    def convert_deprecated_options(args)
      args.map! do |arg|
        case arg
        when '-e', '--emacs'
          deprecate("#{arg} option", '--format emacs', '1.0.0')
          %w(--format emacs)
        else
          arg
        end
      end.flatten!
    end

    def deprecate(subject, alternative = nil, version = nil)
      message =  "#{subject} is deprecated"
      message << " and will be removed in RuboCop #{version}" if version
      message << '.'
      message << " Please use #{alternative} instead." if alternative
      warn message
    end

    def validate_auto_gen_config_option(args)
      return unless args.any?

      warn '--auto-gen-config can not be combined with any other arguments.'
      exit(1)
    end
  end
end