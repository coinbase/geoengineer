require_relative '../spec_helper'

describe("GeoEngineer::Resources::AwsNatGateway") do
  common_resource_tests(GeoEngineer::Resources::AwsNatGateway, 'aws_nat_gateway')

  describe "#_fetch_remote_resources" do
    it 'should create list of hashes from returned AWS SDK' do
      ec2 = AwsClients.ec2
      stub = ec2.stub_data(
        :describe_nat_gateways,
        {
          nat_gateways: [
            {
              nat_gateway_id: 'name1',
              subnet_id: 's1',
              nat_gateway_addresses: [{ allocation_id: 'a1' }]
            },
            {
              nat_gateway_id: 'name2',
              subnet_id: 's2',
              nat_gateway_addresses: [{ allocation_id: 'a2' }]
            }
          ]
        }
      )
      ec2.stub_responses(:describe_nat_gateways, stub)
      remote_resources = GeoEngineer::Resources::AwsNatGateway._fetch_remote_resources(nil)
      expect(remote_resources.length).to eq(2)
    end
  end
end
