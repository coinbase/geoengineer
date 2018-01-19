require_relative '../spec_helper'
require 'time'

describe(GeoEngineer::Resources::AwsKinesisFirehoseDeliveryStream) do
  let(:aws_client) { AwsClients.firehose }

  before do
    aws_client.setup_stubbing
    aws_client.stub_responses(
      :list_delivery_streams,
      {
        delivery_stream_names: [],
        has_more_delivery_streams: false
      }
    )
    aws_client.stub_responses(
      :describe_delivery_stream,
      nil
    )
  end

  common_resource_tests(described_class, described_class.type_from_class_name)
  describe "#_fetch_remote_resources" do
    before do
      aws_client.stub_responses(
        :list_delivery_streams,
        {
          delivery_stream_names: ["data-pipeline-delivery-stream"],
          has_more_delivery_streams: false
        }
      )
    end
    before do
      aws_client.stub_responses(
        :describe_delivery_stream,
        [
          {
            delivery_stream_description: {
              delivery_stream_name: "data-pipeline-delivery-stream",
              delivery_stream_arn:
                "arn:aws:firehose:us-west-1:123:deliverystream/data-pipeline-delivery-stream",
              delivery_stream_status: "ACTIVE",
              delivery_stream_type: "DirectPut",
              version_id: "1",
              create_timestamp: Time.parse("2018-01-19 15:46:52 -0800"),
              destinations: [
                {
                  destination_id: "destinationId-000000000001",
                  s3_destination_description: {
                    role_arn: "arn:aws:iam::123:role/firehose_delivery_role",
                    bucket_arn: "arn:aws:s3:::test-firehose-bucket",
                    prefix: "",
                    buffering_hints: {
                      size_in_m_bs: 5,
                      interval_in_seconds: 300
                    },
                    compression_format: "GZIP",
                    encryption_configuration: {
                      no_encryption_config: "NoEncryption"
                    },
                    cloud_watch_logging_options: {
                      enabled: false
                    }
                  },
                  extended_s3_destination_description: {
                    role_arn: "arn:aws:iam::123:role/firehose_delivery_role",
                    bucket_arn: "arn:aws:s3:::test-firehose-bucket",
                    prefix: "",
                    buffering_hints: {
                      size_in_m_bs: 5,
                      interval_in_seconds: 300
                    },
                    compression_format: "GZIP",
                    encryption_configuration: {
                      no_encryption_config: "NoEncryption"
                    },
                    cloud_watch_logging_options: {
                      enabled: false
                    },
                    processing_configuration: {
                      enabled: false,
                      processors: []
                    },
                    s3_backup_mode: "Disabled"
                  }
                }
              ],
              has_more_destinations: false
            }
          }
        ]
      )
    end

    it 'should create list of hashes from returned AWS SDK' do
      remote_resources =
        GeoEngineer::Resources::AwsKinesisFirehoseDeliveryStream._fetch_remote_resources(nil)
      expect(remote_resources.length).to eq 1
    end
  end
end
