require_relative '../spec_helper'

describe GeoEngineer::Resources::AwsMskCluster do
  let(:aws_client) { AwsClients.kafka }

  common_resource_tests(described_class, described_class.type_from_class_name)

  before { aws_client.setup_stubbing }

  describe '#_fetch_remote_resources' do
    before do
      aws_client.stub_responses(
        :list_clusters,
        {
          cluster_info_list: [
            {
              cluster_name: "msk_name1",
              cluster_arn: "arn:aws:iam::123456789012:user/FakeUser1"
            },
            {
              cluster_name: "msk_name2",
              cluster_arn: "arn:aws:iam::123456789012:user/FakeUser2"
            }
          ]
        }
      )
    end

    it 'should create an array of hashes from the AWS response' do
      resources = GeoEngineer::Resources::AwsMskCluster._fetch_remote_resources(nil)
      expect(resources.count).to eql 2

      test_msk_cluster = resources.first
      expect(test_msk_cluster[:_geo_id]).to eql "msk_name1"
      expect(test_msk_cluster[:_terraform_id]).to eql "arn:aws:iam::123456789012:user/FakeUser1"
    end
  end
end
