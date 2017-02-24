require_relative '../spec_helper'

describe("GeoEngineer::Resources::AwsVpnConnection") do
  common_resource_tests(GeoEngineer::Resources::AwsVpnConnection, 'aws_vpn_connection')
  name_tag_geo_id_tests(GeoEngineer::Resources::AwsVpnConnection)

  describe "#_fetch_remote_resources" do
    let(:ec2) { AwsClients.ec2 }
    before do
      stub = ec2.stub_data(
        :describe_vpn_connections,
        {
          vpn_connections: [
            {
              vpn_connection_id: 'name1',
              customer_gateway_id: 'cg1',
              tags: [{ key: 'Name', value: 'one' }],
              routes: [{ destination_cidr_block: '0.0.0.0/0' }]
            },
            {
              vpn_connection_id: 'name2',
              customer_gateway_id: 'cg2',
              tags: [{ key: 'Name', value: 'two' }],
              routes: [{ destination_cidr_block: '0.0.0.0/0' }]
            }
          ]
        }
      )
      ec2.stub_responses(:describe_vpn_connections, stub)
    end

    after do
      ec2.stub_responses(:describe_vpn_connections, [])
    end

    it 'should create list of hashes from returned AWS SDK' do
      remote_resources = GeoEngineer::Resources::AwsVpnConnection._fetch_remote_resources(nil)
      expect(remote_resources.length).to eq(2)
    end
  end
end
