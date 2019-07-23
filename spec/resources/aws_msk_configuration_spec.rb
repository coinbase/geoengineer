require_relative '../spec_helper'

describe GeoEngineer::Resources::AwsMskConfiguration do
  let(:aws_client) { AwsClients.kafka }

  common_resource_tests(described_class, described_class.type_from_class_name)

  before { aws_client.setup_stubbing }

  describe '#_fetch_remote_resources' do
    before do
      aws_client.stub_responses(
        :list_configurations,
        {
          configurations: [
            {
              name: "msk_config_name1",
              arn: "arn:aws:iam::123456789012:user/FakeUser1",
              description: "This is msk_config_name1",
              creation_time: Time.parse("2019-07-16 17:33:11 utc"),
              kafka_versions: [
                "2.3.0",
                "2.2.1"
              ],
              latest_revision:
              {
                creation_time: Time.parse("2019-07-16 13:37:11 utc"),
                description: "This is the final revision",
                revision: 42
              }
            },
            {
              name: "msk_config_name2",
              arn: "arn:aws:iam::123456789012:user/FakeUser2",
              description: "This is msk_config_name2",
              creation_time: Time.parse("2019-07-16 17:33:11 utc"),
              kafka_versions: [
                "2.3.0",
                "2.2.1"
              ],
              latest_revision:
              {
                creation_time: Time.parse("2019-07-16 13:37:11 utc"),
                description: "This is the final revision",
                revision: 24
              }
            }
          ]
        }
      )
    end

    it 'should create an array of hashes from the AWS response' do
      resources = GeoEngineer::Resources::AwsMskConfiguration._fetch_remote_resources(nil)
      expect(resources.count).to eql 2

      test_msk_config = resources.first
      expect(test_msk_config[:_terraform_id]).to eql "arn:aws:iam::123456789012:user/FakeUser1"
      expect(test_msk_config[:_geo_id]).to eql "msk_config_name1"
    end
  end
end
