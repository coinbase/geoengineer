require_relative '../spec_helper'

describe GeoEngineer::Resources::AwsDaxSubnetGroup do
  let(:aws_client) { AwsClients.dax }

  before { aws_client.setup_stubbing }

  common_resource_tests(described_class, described_class.type_from_class_name)

  describe "#_fetch_remote_resources" do
    before do
      aws_client.stub_responses(
        :describe_subnet_groups,
        {
          subnet_groups: [
            { subnet_group_name: 'test-subnet-group-1' },
            { subnet_group_name: 'test-subnet-group-2' }
          ]
        }
      )
    end

    let(:remote_resources) { described_class._fetch_remote_resources(nil) }

    it 'returns the correct number of resources' do
      expect(remote_resources.length).to eq 2
    end

    it 'maps subnet group name as the unique identifier' do
      expect(remote_resources.all? { |res| res['subnet_group_name'] == res['_geo_id'] && res['subnet_group_name'] == res['_terraform_id'] }).to eq true # rubocop:disable Metrics/LineLength
    end
  end
end
