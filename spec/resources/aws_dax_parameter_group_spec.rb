require_relative '../spec_helper'

describe GeoEngineer::Resources::AwsDaxParameterGroup do
  let(:aws_client) { AwsClients.dax }

  before { aws_client.setup_stubbing }

  common_resource_tests(described_class, described_class.type_from_class_name)

  describe "#_fetch_remote_resources" do
    before do
      aws_client.stub_responses(
        :describe_parameter_groups,
        {
          parameter_groups: [
            {
              parameter_group_name: 'test-parameter-group-1',
              description: 'A test parameter group'
            },
            {
              parameter_group_name: 'test-parameter-group-2',
              description: 'Another test parameter group'
            }
          ]
        }
      )
    end

    let(:remote_resources) { described_class._fetch_remote_resources(nil) }

    it 'returns the correct number of resources' do
      expect(remote_resources.length).to eq 2
    end

    it 'maps parameter group name as the unique identifier' do
      expect(remote_resources.all? { |res| res['parameter_group_name'] == res['_geo_id'] && res['parameter_group_name'] == res['_terraform_id'] }).to eq true # rubocop:disable Metrics/LineLength
    end
  end
end
