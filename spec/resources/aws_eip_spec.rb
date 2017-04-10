require_relative '../spec_helper'

describe GeoEngineer::Resources::AwsEip do
  let(:aws_client) { AwsClients.ec2 }

  common_resource_tests(described_class, described_class.type_from_class_name)

  describe '#_fetch_remote_resources' do
    before do
      aws_client.stub_responses(
        :describe_addresses, {
          addresses: [
            { public_ip: '99.0.0.0', allocation_id: "eipalloc-xxxxxxxx" },
            { public_ip: '99.0.0.1', allocation_id: "eipalloc-xxxxxxxy" }
          ]
        }
      )
    end

    it 'should create an array of hashes from the AWS response' do
      resources = GeoEngineer::Resources::AwsEip._fetch_remote_resources(nil)
      expect(resources.count).to eql 2

      test_eip = resources.first
      expect(test_eip[:_terraform_id]).to eql "eipalloc-xxxxxxxx"
      expect(test_eip[:_geo_id]).to eql "99.0.0.0"
    end
  end
end
