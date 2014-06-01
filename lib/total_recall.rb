require 'yaml'
require "thor"
require "mustache"
require 'csv'

module TotalRecall
  class Helper
    require 'highline/import'
    require "terminal-table"

    attr_reader :config
    attr_accessor :row

    def initialize(config = {})
      @config = config
    end

    def with_row(row, &block)
      @row = row
      instance_eval(&block)
    ensure
      @row = nil
    end

    def highline
      @highline ||= HighLine.new($stdin, $stderr)
    end

    def ask(question, &block)
      highline.ask(question, &block)
    end

    # Prompts the user for an account-name.
    #
    # @param question [String] the question
    # @param options [Hash]
    # @option options [String] :default (nil) account-name that will be used
    #   if no input is provided.
    #
    # @example
    #   ask_account("What account did this money come from?",
    #               default: 'Expenses:Various')
    #   What account did this money come from?  |Expenses:Various|
    #   _
    #
    # @return [String] the account-name
    def ask_account(question, default: nil)
      highline.ask(question) do |q|
        q.default = default if default
      end
    end

    def render_row(columns: [])
      _row = columns.map{|i| row[i] }
      $stderr.puts Terminal::Table.new(rows: [ _row ])
    end
  end

  class Config
    YAML::add_builtin_type('proc') {|_, val| eval("proc{ #{val} }") }

    def initialize(file: 'total_recall.yml')
      @config_file = File.expand_path(file)
    end

    def config
      @config ||= YAML.load_file(@config_file)
    end

    def csv_file
      config[:csv][:file] &&
        File.expand_path(config[:csv][:file], File.dirname(@config_file))
    end

    def csv
      @csv ||= begin
        csv_raw = csv_file ? File.read(csv_file) : config[:csv][:raw]
        CSV.parse(csv_raw, config[:csv][:options] || {})
      end
    end

    def template_file
      config[:template][:file] &&
        File.expand_path(config[:template][:file], File.dirname(@config_file))
    end

    def template
      @template ||= begin
        template_file ? File.read(template_file) : config[:template][:raw]
      end
    end

    def session
      @session ||= Helper.new(config)
    end

    def context
      @context ||= config[:context].merge(transactions: transactions)
    end

    def transactions
      @transactions ||= begin
        csv.each_with_object([]) do |row, result|
          result << transaction_defaults.merge(transactions_config).each_with_object({}) do |(k,v), cfg|
            next if k[/^__/]
            cfg[k] = v.respond_to?(:call) ? session.with_row(row, &v) : v
          end
        end
      end
    end

    def transaction_defaults
      @transaction_defaults ||= begin
        defaults = transactions_config[:__defaults__] || {}
        defaults.each_with_object({}) do |(k,v), result|
          result[k] = v.respond_to?(:call) ? session.with_row(nil, &v) : v
        end
      end
    end

    def transactions_config
      config[:context][:transactions]
    end

    def ledger
      Mustache.render(template, context)
    end
  end

  class Cli < Thor
    require 'total_recall/version'

    include Thor::Actions
    source_root File.expand_path('../total_recall/templates', __FILE__)

    desc "ledger", "Convert the config to a ledger"
    method_option :config, :aliases => "-c", :desc => "Config file", :required => true
    def ledger
      puts TotalRecall::Config.new(file: File.expand_path(options[:config])).ledger
    end

    desc "sample", "Generate an annotated config"
    def sample
      @version = TotalRecall::VERSION
      template("sample.yml.tt")

      say "Now run '#{$0} ledger -c sample.yml' to generate the ledger"
    end

    desc "init NAME", "Generate a minimal config NAME.yml"
    def init(name = "total_recall")
      destination = name + ".yml"

      @version = TotalRecall::VERSION
      @name = name
      template("simple.yml.tt", destination)
    end
  end
end
