require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe TotalRecall::BankParser do
  context '#parse' do
    subject{ described_class.new(:strategy => TotalRecall::ParseStrategy::Abn.new) }

    it "should return an Array" do
      subject.parse(fixture_contents('abn')).class.should == Array
    end
  end
end


shared_examples "a parser" do
  context '#parse_row' do
    it "should return a hash" do
      CSV.parse(fixture_contents(@fixture), subject.options).each do |i|
        parsed_row = subject.parse_row(i)

        parsed_row.class.should == Hash
      end
    end

    it "should return the correct keys and classes" do
      expected_keys_and_classes = {
        :amount => Float,
        :currency => String,
        :description => String,
        :date => Date
      }

      CSV.parse(fixture_contents(@fixture), subject.options).each do |i|
        parsed_row = subject.parse_row(i)

        parsed_row.keys.should =~ expected_keys_and_classes.keys
        expected_keys_and_classes.each do |key, klass|
          parsed_row.send(:[], key).class.should == klass
        end
      end
    end
  end
end

describe TotalRecall::ParseStrategy::Abn do
  before{ @fixture = 'abn' }
  it_behaves_like "a parser"
end

describe TotalRecall::ParseStrategy::Ing do
  before{ @fixture = 'ing' }
  it_behaves_like "a parser"
end

describe TotalRecall::ParseStrategy::AbnCC do
  before{ @fixture = 'abncc' }
  it_behaves_like "a parser"
end
