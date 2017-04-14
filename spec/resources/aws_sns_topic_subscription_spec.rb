require_relative '../spec_helper'

describe(GeoEngineer::Resources::AwsSnsTopic) do
  common_resource_tests(described_class, described_class.type_from_class_name)
  let(:sns_client) { AwsClients.sns }
  before { sns_client.setup_stubbing }

  describe "#_fetch_remote_resources" do
    it 'should create list of hashes from returned AWS SDK' do
      # list_subscriptions.subscriptions
      stub = sns_client.stub_data(
        :list_subscriptions,
        {
          subscriptions: [
            {
              subscription_arn: 'arn:aws:sns:us-east-1:123456789012:fake_arn:8b93e9cd-ef23-47f3',
              topic_arn: 'arn:aws:sns:us-east-1:123456789012:fake_arn',
              endpoint: 'arn:aws:sqs:us-east-1:123456789012:fake_arn',
              protocol: 'sqs'
            },
            {
              subscription_arn: 'arn:aws:sns:us-east-1:123456789012:fake_arn:8b93e9cd-ef23-47f3',
              topic_arn: 'arn:aws:sns:us-east-1:123456789012:fake_arn',
              endpoint: 'arn:aws:sqs:us-east-1:123456789012:fake_arn',
              protocol: 'sqs'
            }
          ]
        }
      )
      sns_client.stub_responses(:list_subscriptions, stub)
      remote_resources = GeoEngineer::Resources::AwsSnsTopicSubscription
                         ._fetch_remote_resources(nil)
      expect(remote_resources.length).to eq 2
    end
  end
end
