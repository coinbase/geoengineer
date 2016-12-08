require_relative '../spec_helper'

describe("GeoEngineer::Resources::AwsVpnGateway") do
  common_resource_tests(GeoEngineer::Resources::AwsVpnGateway, 'aws_vpn_gateway')
  name_tag_geo_id_tests(GeoEngineer::Resources::AwsVpnGateway)

  describe "#_fetch_remote_resources" do
    it 'should create list of hashes from returned AWS SDK' do
      ec2 = AwsClients.ec2
      stub = ec2.stub_data(
        :describe_vpn_gateways,
        {
          vpn_gateways: [
            { vpn_gateway_id: 'name1', tags: [{ key: 'Name', value: 'one' }] },
            { vpn_gateway_id: 'name2', tags: [{ key: 'Name', value: 'two' }] }
          ]
        }
      )
      ec2.stub_responses(:describe_vpn_gateways, stub)
      remote_resources = GeoEngineer::Resources::AwsVpnGateway._fetch_remote_resources
      expect(remote_resources.length).to eq(2)
    end
  end
end
