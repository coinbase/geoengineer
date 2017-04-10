require_relative '../spec_helper'

describe GeoEngineer::Resources::AwsCloudwatchEventRule do
  let(:aws_client) { AwsClients.cloudwatchevents }

  before { aws_client.setup_stubbing }

  common_resource_tests(described_class, described_class.type_from_class_name)

  describe "#_fetch_remote_resources" do
    before do
      aws_client.stub_responses(
        :list_rules,
        {
          rules:
          [
            {
              name: "test",
              arn: "arn:aws:cloudwatchevents:us-east-1:1234567890:test",
              state: "ENABLED",
              schedule_expression: "rate(5 minutes)"
            }
          ]
        }
      )
    end

    it 'should create list of hashes from returned AWS SDK' do
      remote_resources = GeoEngineer::Resources::AwsCloudwatchEventRule._fetch_remote_resources(nil)
      expect(remote_resources.length).to eq 1
    end
  end
end
