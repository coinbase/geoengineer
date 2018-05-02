require_relative '../spec_helper'

describe GeoEngineer::Resources::AwsCloudwatchLogGroup do
  let(:aws_client) { AwsClients.cloudwatchlogs }

  before { aws_client.setup_stubbing }
  common_resource_tests(described_class, described_class.type_from_class_name)

  describe "#_fetch_remote_resources" do
    before do
      aws_client.stub_responses(
        :describe_log_groups,
        {
          log_groups: [
            { log_group_name: 'name1',
              creation_time: 1,
              metric_filter_count: 0,
              arn: "no",
              stored_bytes: -1 }
          ]
        }
      )
    end

    it 'should create list of hashes from returned AWS SDK' do
      remote_resources = GeoEngineer::Resources::AwsCloudwatchLogGroup._fetch_remote_resources(nil)
      expect(remote_resources.length).to eq 1
    end
  end
end
