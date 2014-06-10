require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe TotalRecall::Config do
  include FakeFS::SpecHelpers

  def stubbed_file(path, content)
    # SOURCE http://edgeapi.rubyonrails.org/classes/String.html#method-i-strip_heredoc
    indent = content.scan(/^[ \t]*(?=\S)/).min.size rescue 0
    content = content.gsub(/^[ \t]{#{indent}}/, '')

    FakeFS do
      File.open(path, 'w'){|f| f.print content }
    end
  end

  def instance_with_config(config, options = {})
    options = {file: 'config.yml'}.merge(options)
    stubbed_file(options[:file], config)
    described_class.new(options)
  end

  describe '#config' do
    it 'yields the config as hash' do
      instance = instance_with_config(<<-CONFIG)
      :csv:
        :raw: Some csv
      :a: 1
      CONFIG

      expect(instance.config).to eql({csv: { raw: 'Some csv'}, a: 1})
    end
  end

  describe '#csv' do
    it 'yields csv assigned to :raw' do
      instance = instance_with_config(<<-CONFIG)
      :csv:
        :raw: Some csv
      CONFIG

      expect(instance.csv).to eql(CSV.parse('Some csv'))
    end

    it 'yields csv from file :file' do
      csv_file = stubbed_file('some.csv', 'Some csv')
      instance = instance_with_config(<<-CONFIG)
      :csv:
        :file: some.csv
      CONFIG

      expect(instance.csv).to eql(CSV.parse('Some csv'))
    end

    it 'yields csv from :file when both :raw and :file are configured' do
      csv_file = stubbed_file('some.csv', 'Some csv')
      instance = instance_with_config(<<-CONFIG)
      :csv:
        :file: some.csv
        :raw: Some raw csv
      CONFIG

      expect(instance.csv).to eql(CSV.parse('Some csv'))
    end

    specify 'csv-options are passed on to CSV#read' do
      instance = instance_with_config(<<-CONFIG)
      :csv:
        :options:
          :option1: true
      CONFIG

      expect(CSV).to receive(:parse).with(anything(), { option1: true })
      instance.csv
    end
  end

  describe '#template' do
    it 'yields template assigned to :raw' do
      instance = instance_with_config(<<-CONFIG)
      :template:
        :raw: |-
          Raw template
          here
      CONFIG

      expect(instance.template).to eql("Raw template\nhere")
    end

    it 'yields template from file :file' do
      template_file = stubbed_file('template.mustache', 'File template')
      instance = instance_with_config(<<-CONFIG)
      :template:
        :file: template.mustache
      CONFIG

      expect(instance.template).to eql('File template')
    end

    it 'yields template from :file when both :raw and :file are configured' do
      template_file = stubbed_file('template.mustache', 'File template')
      instance = instance_with_config(<<-CONFIG)
      :template:
        :file: template.mustache
        :raw: Raw template
      CONFIG

      expect(instance.template).to eql('File template')
    end
  end

  describe 'YAML types' do
    it 'allows proc-types' do
      instance = instance_with_config(<<-CONFIG)
      :a: !!proc 1 + 1
      :b: !!proc |
        1 + 1
      CONFIG

      expect(instance.config[:a].call).to eq 2
      expect(instance.config[:b].call).to eq 2
    end
  end

  describe '#context' do
    it 'has a transaction per line of csv' do
      instance = instance_with_config(<<-CONFIG)
      :csv:
        :raw: |-
          1
          1
      :context:
        :transactions:
          :from: From
          :to: !!proc 1 + 1
          :amount: !!proc row[0]
      CONFIG

      transactions = instance.context[:transactions]
      expect(transactions.size).to eq 2

      transaction = transactions.first
      expect(transaction).to match({from: 'From', to: 2, amount: "1"})
    end

    it 'adds defaults to every transaction' do
      instance = instance_with_config(<<-CONFIG)
      :csv:
        :raw: |-
          line 1
          line 2
      :context:
        :transactions:
          :__defaults__:
            :default: !!proc 1
          :from: From
      CONFIG

      transaction = instance.context[:transactions].first

      expect(transaction).to match({from: 'From', default: 1})
    end

    it 'may contain any other settings' do
      instance = instance_with_config(<<-CONFIG)
      :csv:
        :raw: some csv
      :context:
        :transactions:
          :from: From
        :a: 1
      CONFIG

      expect(instance.context).to match(transactions: [{from: 'From'}], a: 1)
    end
  end

  describe 'helper methods' do
    describe '#transaction' do
      it 'gives access to the existing attributes' do
        instance = instance_with_config(<<-CONFIG)
        :csv:
          :raw: some csv
        :context:
          :transactions:
            :a: attribute a
            :b: !!proc |
              %|not %s| % transaction.a
        CONFIG

        expect(instance.transactions.first).to match({a: 'attribute a', b: 'not attribute a'})
      end
    end

    describe '#config' do
      it 'gives access to the full config' do
        instance = instance_with_config(<<-CONFIG)
        :csv:
          :raw: some csv
        :context:
          :transactions:
            :a: !!proc |
              config[:a]
        :a: 1
        CONFIG

        expect(instance.transactions.first).to match({a: 1})
      end
    end

    describe '#default' do
      it 'gives access to the default' do
        instance = instance_with_config(<<-CONFIG)
        :csv:
          :raw: some csv
        :context:
          :transactions:
            :__defaults__:
              :a: !!proc 2
              :b?: true
            :a: !!proc |
              default.succ
            :b?: true
        CONFIG

        expect(instance.transactions.first).to match({a: 3, b?: true})
      end
    end
  end
end
