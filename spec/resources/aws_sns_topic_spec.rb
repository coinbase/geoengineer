require_relative '../spec_helper'

describe(GeoEngineer::Resources::AwsSnsTopic) do
  let(:sns_client) { AwsClients.sns }
  before { sns_client.setup_stubbing }

  common_resource_tests(described_class, described_class.type_from_class_name)

  common_resource_tests(described_class, described_class.type_from_class_name)

  describe "#_fetch_remote_resources" do
    it 'should create list of hashes from returned AWS SDK' do
      stub = sns_client.stub_data(
        :list_topics,
        {
          topics: [
            { topic_arn: 'arn:aws:sns:us-east-1:123456789012:fake_arn' },
            { topic_arn: 'arn:aws:sns:us-east-1:123456789012:another_fake_arn' }
          ]
        }
      )
      sns_client.stub_responses(:list_topics, stub)
      remote_resources = GeoEngineer::Resources::AwsSnsTopic._fetch_remote_resources(nil)
      expect(remote_resources.length).to eq 2
    end
  end
end
