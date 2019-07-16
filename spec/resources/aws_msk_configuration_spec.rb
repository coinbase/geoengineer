require_relative '../spec_helper'

describe GeoEngineer::Resources::AwsMskConfiguration do
  let(:aws_client) { AwsClients.kafka }

  common_resource_tests(described_class, described_class.type_from_class_name)

  describe '#_fetch_remote_resources' do
    before do
      aws_client.stub_responses(
        :list_configurations, { configurations: [{ name: "msk_config_name1" },
                                                 { name: "msk_config_name2" }] }
      )
    end

    it 'should create an array of hashes from the AWS response' do
      resources = GeoEngineer::Resources::AwsMskConfiguration._fetch_remote_resources(nil)
      expect(resources.count).to eql 2

      test_msk_config = resources.first
      expect(test_msk_config[:_terraform_id]).to eql "msk_config_name1"
      expect(test_msk_config[:_geo_id]).to eql "msk_config_name1"
    end
  end
end
