require_relative '../spec_helper'

describe GeoEngineer::Resources::AwsLambdaEventSourceMapping do
  let(:aws_client) { AwsClients.lambda }

  before { aws_client.setup_stubbing }

  common_resource_tests(described_class, described_class.type_from_class_name)

  describe '#_fetch_remote_resources' do
    before do
      aws_client.stub_responses(
        :list_event_source_mappings, {
          event_source_mappings: [
            {
              uuid: "1",
              event_source_arn: "arn:aws:kinesis:one",
              function_arn: "arn:aws:lambda:function:foo"
            },
            {
              uuid: "2",
              event_source_arn: "arn:aws:kinesis:two",
              function_arn: "arn:aws:lambda:function:bar:beta"
            }
          ]
        }
      )
    end

    after { aws_client.stub_responses(:list_event_source_mappings, {}) }

    it 'should create an array of hashes from the AWS response' do
      resources = GeoEngineer::Resources::AwsLambdaEventSourceMapping._fetch_remote_resources(nil)
      expect(resources.count).to eql(2)
    end
  end

  describe "#_extract_name_from_arn" do
    it "returns nil if ARN does not contain function" do
      expect(described_class._extract_name_from_arn("foo_bar")).to be_nil
    end

    it "returns item directly after function in ARN" do
      expect(described_class._extract_name_from_arn("function:bar")).to eq('bar')
      expect(described_class._extract_name_from_arn("aws:function:baz")).to eq('baz')
      expect(described_class._extract_name_from_arn("aws:function:foo:qux")).to eq('foo')
      expect(described_class._extract_name_from_arn("aws:function")).to be_nil
    end
  end
end
