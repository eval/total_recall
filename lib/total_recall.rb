require "total_recall/version"
require "thor"
require "mustache"

module TotalRecall
  module ParseStrategy
    class IngCC
      require 'time'

      def parse_row(row)
        amount = row[2].sub(/\./,'').sub(/,/,'.').to_f
        {
          :date => Date.parse(row[0]),
          :amount => amount,
          :description => row[1],
          :currency => 'EUR'
         }
      end

      def self.options
        {:col_sep => ";", :headers => false}
      end

      def options
        self.class.options
      end
    end # /IngCC

    class Ing
      require 'time'

      # Expected: Hash with:
      #:amount => Float,
      #:currency => String,
      #:description => String,
      #:date => Date
      def parse_row(row)
        amount = row[6].sub(/,/,'.').to_f
        {
          :amount => (row[5] == 'Bij' ? amount : -amount),
          :date => Date.parse(row[0]),
          :description => [row[1], row[8]].map{|i| i.strip.gsub(/\s+/, ' ')}.join(' '),
          :currency => 'EUR'
        }
      end


      def self.options
        {:col_sep => ",", :headers => true}
      end

      def options
        self.class.options
      end
    end # /Ing

    class Abn
      require 'time'

      # Expected: Hash with:
      #:amount => Float,
      #:currency => String,
      #:description => String,
      #:date => Date
      def parse_row(row)
        {
          :amount => row[6].sub(/,/,'.').to_f,
          :date => Date.parse(row[2]),
          :description => row[7].strip.gsub(/\s+/,' '),
          :currency => row[1]
        }
      end

      def self.options
        {:col_sep => "\t"}
      end

      def options
        self.class.options
      end
    end # /Abn

    class AbnCC
      require 'time'

      # Expected: Hash with:
      #:amount => Float,
      #:currency => String,
      #:description => String,
      #:date => Date
      def parse_row(row)
        amount = row[2].sub(/,/,'.').to_f
        {
          :amount => (row[8] == 'D' ? -amount : amount),
          :date => Date.parse(row[0]),
          :description => row[3],
          :currency => 'EUR'
        }
      end

      def self.options
        {:col_sep => ",", :headers => true}
      end

      def options
        self.class.options
      end
    end # /AbnCC
  end # /ParseStrategy

  class Ledger < Mustache
    attr_reader :default_account, :options

    def initialize(default_account, transactions, options={})
      @options = {:max_account_width => 80, :decimal_mark => ','}.merge(options)
      @default_account = default_account
      @_transactions = transactions
    end

    def transactions
      @transactions ||= begin
        @_transactions.map do |i|
          res = {}
          res[:to], res[:from] = (i[:amount] > 0 ? [default_account, i[:account]] : [i[:account], default_account])
          if i[:tags].any?
            tagsline = "\n  ; :%s:" % (i[:tags] * ':')
            tagskey = i[:amount] > 0 ? :from_tags : :to_tags
            res[tagskey] = tagsline
          end
          res[:amount] = fmt_amount(i[:amount].abs)
          res[:description], res[:date], res[:currency] = i[:description], i[:date], i[:currency]
          res[:spacer] = " " * (options[:max_account_width] - res[:to].size)
          res
        end
      end
    end


    def self.template;<<-TEMPLATE
{{# transactions}}
{{date}} {{description}}
  {{to}}  {{spacer}}{{currency}} {{amount}}{{to_tags}}
  {{from}}{{from_tags}}

{{/ transactions}}
TEMPLATE
    end

    protected
      def fmt_amount(amount)
        ("%10.2f" % amount).split('.') * options[:decimal_mark]
      end
  end

  class AccountGuesser
    attr_reader :accounts, :tokens

    def initialize
      @accounts = {}
      @tokens = {}
    end

    # copied from reckon(https://github.com/iterationlabs/reckon)
    def guess(data)
      query_tokens = tokenize(data)

      search_vector = []
      account_vectors = {}

      query_tokens.each do |token|
        idf = Math.log((accounts.keys.length + 1) / ((tokens[token] || {}).keys.length.to_f + 1))
        tf = 1.0 / query_tokens.length.to_f
        search_vector << tf*idf

        accounts.each do |account, total_terms|
          tf = (tokens[token] && tokens[token][account]) ? tokens[token][account] / total_terms.to_f : 0
          account_vectors[account] ||= []
          account_vectors[account] << tf*idf
        end
      end

      # Should I normalize the vectors?  Probably unnecessary due to tf-idf and short documents.
      account_vectors = account_vectors.to_a.map do |account, account_vector|
        { :cosine => (0...account_vector.length).to_a.inject(0) { |m, i| m + search_vector[i] * account_vector[i] },
          :account => account }
      end

      account_vectors.sort! {|a, b| b[:cosine] <=> a[:cosine] }
      account_vectors.first && account_vectors.first[:account]
    end

    # copied from reckon(https://github.com/iterationlabs/reckon)
    def learn(account, data)
      accounts[account] ||= 0
      tokenize(data).each do |token|
        tokens[token] ||= {}
        tokens[token][account] ||= 0
        tokens[token][account] += 1
        accounts[account] += 1
      end
    end

    protected
      def tokenize(str)
        str.downcase.split(/[\s\-]/)
      end
  end

  class BankParser
    require 'csv'
    attr_reader :strategy

    def initialize(options={})
      @strategy = options[:strategy]
    end

    # Parses csv content and returns array of hashes.
    #
    # @example
    #   parser = TotalRecall::BankParser.new(:strategy => TotalRecall::ParseStrategy::Some.new)
    #   parser.parse("12.1\n1.99") #=> [{:amount => 12.1}, {:amount => 1.99}]
    #
    # @param [String] str content of csv to parse.
    # @return [Array<Hash>]
    def parse(str, options={})
      options = strategy.options.merge(options)

      result = []
      CSV.parse(str, options){|row| result << strategy.parse_row(row)}
      result
    end
  end #/BankParser


  class Cli < Thor
    require "terminal-table"
    require "highline/import"
    require "bayes_motel"

    no_tasks do
      def self.strategies
        {
          'abn' => TotalRecall::ParseStrategy::Abn,
          'ing' => TotalRecall::ParseStrategy::Ing,
          'ingcc' => TotalRecall::ParseStrategy::IngCC,
          'abncc' => TotalRecall::ParseStrategy::AbnCC
        }
      end

      def highline
        @highline ||= HighLine.new($stdin, $stderr)
      end

      def strategies
        self.class.strategies
      end

      def parser(strategy)
        TotalRecall::BankParser.new(:strategy => strategy)
      end
    end

    desc "ledger", "Convert input to ledger-transactions"
    method_option :input, :aliases => "-i", :desc => "CSV file to use for input", :required => true
    method_option :parser, :aliases => "-p", :desc => "Parser to use (one of #{strategies.keys.inspect})", :required => true
    def ledger
      strategy = strategies[options[:parser]]
      file_contents = File.read(options[:input])
      rows = parser(strategy.new).parse(file_contents)

      guesser = AccountGuesser.new

      default_account = highline.ask("What is the account name of this bank account in Ledger?\n> ")
      transactions = [] # [{<row>, :account => 'Expenses:Car'}, ...]
      tags = []
      start_from = 0
      begin
        rows.each_with_index do |row, ix|
          if start_from && start_from != ix
            next
          elsif start_from
            start_from = nil
          end

          guessed = guesser.guess(row[:description])
          question = row[:amount] > 0 ? "What account provided this income?" : "To which account did this money go?"

          $stderr.puts Terminal::Table.new(:rows => [ [ row[:date], row[:amount], row[:description] ] ])
          account = highline.ask("#{question} (#{guessed}) or [d]one, [s]kip, [p]revious\n> ")
          account = account.empty? ? guessed : account # defaults not working
          case account
          when 'd'
            break
          when 's'
            next
          when 'p'
            transactions.pop
            start_from = [0, (ix - 1)].max
            raise
          end

          transaction_tags = []
          loop do
            tag = highline.choose do |menu|
              menu.shell = true
              menu.prompt = "Add tags? "
              menu.prompt << "(#{transaction_tags.join(',')})" if transaction_tags.any?

              menu.choices('Done'){ nil }
              menu.choices(*tags - transaction_tags)
              menu.choice('New...'){ newtag = highline.ask('Tag: ');tags << newtag; newtag }
            end
            break unless tag
            transaction_tags << tag
          end

          guesser.learn(account, row[:description])
          transactions << row.merge(:account => account, :tags => transaction_tags)
        end
      rescue
        $stderr.puts "Let's do that again"
        retry
      end

      puts Ledger.new(default_account, transactions).render
    end

    desc "parse", "Parses input-file and prints it"
    method_option :input, :aliases => "-i", :desc => "CSV file to use for input", :required => true
    method_option :parser, :aliases => "-p", :desc => "Parser to use (one of #{strategies.keys.join(',')})", :required => true
    def parse
      strategy = strategies[options[:parser]]
      file_contents = File.read(options[:input])
      data = parser(strategy.new).parse(file_contents)

      table = Terminal::Table.new do |t|
        t.headings = 'Date', 'Amount', 'Description'
        data.each do |row|
          next unless row
          t << [ row[:date], row[:amount], row[:description] ]
        end
      end
      puts table
    end

  end
end
