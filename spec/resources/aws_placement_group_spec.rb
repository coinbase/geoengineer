require_relative '../spec_helper'

describe GeoEngineer::Resources::AwsPlacementGroup do
  let(:aws_client) { AwsClients.ec2 }

  common_resource_tests(described_class, described_class.type_from_class_name)

  describe '#_fetch_remote_resources' do
    before do
      aws_client.stub_responses(
        :describe_placement_groups, {
          placement_groups: [
            { group_name: 'some-placement-group', state: 'available', strategy: 'cluster' },
            { group_name: 'other-placement-group', state: 'available', strategy: 'cluster' }
          ]
        }
      )
    end

    it 'creates an array of hashes from the AWS response' do
      resources = described_class._fetch_remote_resources(nil)
      expect(resources.count).to eql 2

      test_eip = resources.first
      expect(test_eip[:_terraform_id]).to eql 'some-placement-group'
      expect(test_eip[:_geo_id]).to eql 'some-placement-group'
    end
  end
end
