require_relative '../spec_helper'

describe("GeoEngineer::Resources::AwsSnsTopic") do
  common_resource_tests(GeoEngineer::Resources::AwsSnsTopic, 'aws_sns_topic')

  describe "#_fetch_remote_resources" do
    it 'should create list of hashes from returned AWS SDK' do
      sns = AwsClients.sns
      stub = sns.stub_data(
        :list_topics,
        {
          topics: [
            { topic_arn: 'arn:aws:sns:us-east-1:123456789012:fake_arn' },
            { topic_arn: 'arn:aws:sns:us-east-1:123456789012:another_fake_arn' }
          ]
        }
      )
      sns.stub_responses(:list_topics, stub)
      remote_resources = GeoEngineer::Resources::AwsSnsTopic._fetch_remote_resources
      expect(remote_resources.length).to eq 2
    end
  end
end
