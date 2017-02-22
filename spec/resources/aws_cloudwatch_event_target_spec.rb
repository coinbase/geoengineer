require_relative '../spec_helper'

describe("GeoEngineer::Resources::AwsCloudwatchEventTarget") do
  let(:aws_client) { AwsClients.cloudwatchevents }

  before do
    aws_client.setup_stubbing
  end

  common_resource_tests(
    GeoEngineer::Resources::AwsCloudwatchEventTarget,
    'aws_cloudwatch_event_target'
  )

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
    before do
      aws_client.stub_responses(
        :list_targets_by_rule,
        {
          targets:
          [
            {
              id: "test",
              arn: "arn:aws:cloudwatchevents:us-east-1:1234567890:test",
              input: nil,
              input_path: nil
            }
          ]
        }
      )
    end

    it 'should create list of hashes from returned AWS SDK' do
      remote_resources = GeoEngineer::Resources::AwsCloudwatchEventTarget
                         ._fetch_remote_resources(nil)
      expect(remote_resources.length).to eq 1
    end
  end
end
