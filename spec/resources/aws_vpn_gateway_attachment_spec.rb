require_relative '../spec_helper'

describe("GeoEngineer::Resources::AwsVpnGatewayAttachment") do
  common_resource_tests(
    GeoEngineer::Resources::AwsVpnGatewayAttachment,
    'aws_vpn_gateway_attachment'
  )

  describe "#_fetch_remote_resources" do
    let(:ec2) { AwsClients.ec2 }
    before do
      stub = ec2.stub_data(
        :describe_vpn_gateways,
        {
          vpn_gateways: [
            {
              vpn_gateway_id: 'name1',
              tags: [{ key: 'Name', value: 'one' }],
              vpc_attachments: [{ vpc_id: 'v1' }]
            },
            {
              vpn_gateway_id: 'name2',
              tags: [{ key: 'Name', value: 'two' }],
              vpc_attachments: [{ vpc_id: 'v1' }]
            }
          ]
        }
      )
      ec2.stub_responses(:describe_vpn_gateways, stub)
    end

    after do
      ec2.stub_responses(:describe_vpn_gateways, [])
    end

    it 'should create list of hashes from returned AWS SDK' do
      remote_resources = GeoEngineer::Resources::AwsVpnGatewayAttachment
                         ._fetch_remote_resources(nil)
      expect(remote_resources.length).to eq(2)
    end
  end
end
