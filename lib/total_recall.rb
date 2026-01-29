# frozen_string_literal: true

require "yaml"
require "thor"
require "mustache"
require "csv"

module TotalRecall
  module DefaultHelper
    require "highline"
    require "terminal-table"

    def transaction
      self
    end

    def config
      @config
    end

    def row
      @row
    end

    def default
      @default
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
    def ask_account(question, options = {})
      options = {default: nil}.merge(options)
      highline.ask(question) do |q|
        q.default = options[:default] if options[:default]
      end
    end

    def render_row(options = {})
      options = {columns: []}.merge(options)
      table_row = options[:columns].map { |i| row[i] }
      warn Terminal::Table.new(rows: [table_row])
    end

    def extract_transaction(row)
      @row = row
      transactions_config.each do |k, v|
        next if k[/^__/]
        self[k] = value_for(k, v)
      end
      self
    end

    protected

    def value_for(key, v)
      if v.respond_to?(:call)
        @default = self[key.to_sym]
        instance_eval(&v)
      else
        v
      end
    ensure
      @default = nil
    end

    def transactions_config
      config[:context][:transactions]
    end

    def highline
      @highline ||= HighLine.new($stdin, $stderr)
    end
  end

  # Include your module into {SessionHelper} if you want to
  # add helpers or redefine existing ones.
  #
  # @example
  #   module MyExtension
  #     def guess_account(question, options = {})
  #       guess = AccountGuesser.new.guess
  #       ask_account("What acount provided this?", default: guess)
  #     end
  #   end
  #
  #   TotalRecall::SessionHelper.include MyExtension
  module SessionHelper
    include DefaultHelper
  end

  class Config
    YAML.add_builtin_type("proc") { |_, val| eval("proc { #{val} }", binding, __FILE__, __LINE__) } # rubocop:disable Security/Eval

    def initialize(options = {})
      options = {file: "total_recall.yml", csv_file: nil}.merge(options)
      @csv_file = File.expand_path(options[:csv_file]) if options[:csv_file]
      @config_file = File.expand_path(options[:file])
      @transactions_only = !!options[:transactions_only]
    end

    def config
      @config ||= YAML.unsafe_load_file(@config_file, symbolize_names: true)
    end

    def csv_file
      @csv_file ||= config[:csv][:file] &&
        File.expand_path(config[:csv][:file], File.dirname(@config_file))
    end

    def csv
      @csv ||= begin
        csv_raw = csv_file ? File.read(csv_file) : config[:csv][:raw]
        CSV.parse(csv_raw, **(config[:csv][:options] || {}))
      end
    end

    def template_file
      config[:template][:file] &&
        File.expand_path(config[:template][:file], File.dirname(@config_file))
    end

    def template
      @template ||= template_file ? File.read(template_file) : config[:template][:raw]
    end

    def transactions_only_template
      @transactions_only_template ||= Mustache::Template.new("").tap do |t|
        transactions_tokens_proc = proc { transactions_tokens }
        t.define_singleton_method(:tokens) do |*|
          transactions_tokens_proc.call
        end
      end
    end

    def transactions_tokens
      @transactions_tokens ||= Mustache::Template.new(template).tokens.detect do |type, tag, *rest|
        type == :mustache && tag == :section &&
          [:mustache, :fetch, ["transactions"]]
      end
    end

    def context
      @context ||= config[:context].merge(transactions: transactions)
    end

    def session
      @session ||= session_class.new(transactions_config_defaults, config: config)
    end

    def transaction_attributes
      @transaction_attributes ||= transactions_config.dup.delete_if { |k, _| k[/__/] }.keys |
        transactions_config_defaults.keys
    end

    def session_class
      @session_class ||= Class.new(Struct.new(*transaction_attributes)) do
        include SessionHelper

        def initialize(values = {}, options = {})
          @config = options[:config]
          values.each do |k, v|
            self[k] = value_for(k, v)
          end
        end
      end
    end

    def transactions
      @transactions ||= csv.each_with_object([]) do |row, transactions|
        transactions << session.extract_transaction(row).each_pair.to_a.to_h
      end
    end

    def transactions_config
      config[:context][:transactions]
    end

    def transactions_config_defaults
      transactions_config[:__defaults__] || {}
    end

    def ledger
      tmp = @transactions_only ?
            transactions_only_template :
            template

      Mustache.render(tmp, context)
    end
  end

  class Cli < Thor
    require "total_recall/version"

    include Thor::Actions

    source_root File.expand_path("../total_recall/templates", __FILE__)

    desc "ledger", "Convert CONFIG to a ledger"
    method_option :config, aliases: "-c", desc: "Config file", required: true
    method_option :require, aliases: "-r", desc: "File to load"
    method_option :csv, aliases: "-f", desc: "csv file"
    method_option :transactions_only, type: :boolean
    def ledger
      load(options[:require]) if options[:require]

      config_path = File.expand_path(options[:config])
      puts TotalRecall::Config.new(file: config_path,
        csv_file: options[:csv],
        transactions_only: options[:transactions_only]).ledger
    end

    desc "sample", "Generate an annotated config"
    def sample
      @version = TotalRecall::VERSION
      template("sample.yml.tt")

      say "Now run '#{$0} ledger -c sample.yml' to generate the ledger"
    end

    desc "init NAME", "Generate a minimal config NAME.yml"
    def init(name = "total_recall")
      destination = name[/\.yml$/] ? name : (name + ".yml")

      @version = TotalRecall::VERSION
      @name = destination.split(/\.yml$/).first
      template("simple.yml.tt", destination)
    end

    desc "version, --version, -v", "Show total_recall version"
    def version
      puts TotalRecall::VERSION
    end
    map %w[-v --version] => :version
  end
end
