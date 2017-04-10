require_relative '../spec_helper'

describe(GeoEngineer::Resources::AwsVpcPeeringConnection) do
  common_resource_tests(described_class, described_class.type_from_class_name)

  describe "#_fetch_remote_resources" do
    let(:ec2) { AwsClients.ec2 }
    before do
      stub = ec2.stub_data(
        :describe_vpc_peering_connections,
        {
          vpc_peering_connections: [
            { vpc_peering_connection_id: 'name1', tags: [{ key: 'Name', value: 'one' }] },
            { vpc_peering_connection_id: 'name1', tags: [{ key: 'Name', value: 'two' }] }
          ]
        }
      )
      ec2.stub_responses(:describe_vpc_peering_connections, stub)
    end

    after do
      ec2.stub_responses(:describe_vpc_peering_connections, [])
    end

    it 'should create list of hashes from returned AWS SDK' do
      remote_resources = GeoEngineer::Resources::AwsVpcPeeringConnection
                         ._fetch_remote_resources(nil)
      expect(remote_resources.length).to eq(2)
    end
  end
end
