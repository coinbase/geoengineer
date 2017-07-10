require_relative '../spec_helper'

describe GeoEngineer::Resources::AwsNetworkInterface do
  let(:aws_client) { AwsClients.ec2 }

  common_resource_tests(described_class, described_class.type_from_class_name)

  describe '#_fetch_remote_resources' do
    before do
      aws_client.stub_responses(
        :describe_network_interfaces, {
          network_interfaces: [
            { network_interface_id: "eni-xxxxxxxx", subnet_id: 'subnet-123456',
              private_ip_addresses: [{ private_ip_address: '99.0.0.0' },
                                     { private_ip_address: '99.0.0.1' }] },
            { network_interface_id: "eni-xxxxxxxy", subnet_id: 'subnet-123456',
              private_ip_addresses: [{ private_ip_address: '99.0.0.2' }] }
          ]
        }
      )
    end

    it 'should create an array of hashes from the AWS response' do
      resources = GeoEngineer::Resources::AwsNetworkInterface._fetch_remote_resources(nil)
      expect(resources.count).to eql 2

      test_interface = resources.first
      expect(test_interface[:_terraform_id]).to eql "eni-xxxxxxxx"
      expect(test_interface[:_geo_id]).to eql "99.0.0.0,99.0.0.1"
    end
  end
end
