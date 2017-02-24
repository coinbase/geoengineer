require_relative '../spec_helper'

describe("GeoEngineer::Resources::AwsKinesisStream") do
  let(:aws_client) { AwsClients.kinesis }

  before do
    aws_client.setup_stubbing
    aws_client.stub_responses(
      :list_streams,
      {
        stream_names: [],
        has_more_streams: false
      }
    )
  end

  common_resource_tests(GeoEngineer::Resources::AwsKinesisStream, 'aws_kinesis_stream')

  describe "#_fetch_remote_resources" do
    before do
      aws_client.stub_responses(
        :list_streams,
        {
          stream_names: ["test"],
          has_more_streams: false
        }
      )
    end
    before do
      aws_client.stub_responses(
        :describe_stream,
        {
          stream_description:
          {
            stream_name: "test",
            stream_arn: "arn:aws:kinesis:us-east-1:1234567890:stream/test",
            stream_status: "ACTIVE",
            stream_creation_timestamp: Time.now,
            shards: [],
            has_more_shards: false,
            retention_period_hours: 24,
            enhanced_monitoring: []
          }
        }
      )
    end

    it 'should create list of hashes from returned AWS SDK' do
      remote_resources = GeoEngineer::Resources::AwsKinesisStream._fetch_remote_resources(nil)
      expect(remote_resources.length).to eq 1
    end
  end
end
