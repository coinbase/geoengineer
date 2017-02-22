require_relative '../spec_helper'

describe("GeoEngineer::Resources::AwsRoute53Zone") do
  let(:aws_client) { AwsClients.route53 }

  before { aws_client.setup_stubbing }

  common_resource_tests(GeoEngineer::Resources::AwsRoute53Zone, 'aws_route53_zone')

  describe '#_fetch_remote_resources' do
    before do
      aws_client.stub_responses(
        :list_hosted_zones, {
          hosted_zones: [
            { id: '123',  name: "testzone", caller_reference: "test" },
            { id: '1234', name: "anothertestzone", caller_reference: "test" }
          ],
          is_truncated: false,
          max_items: 100,
          marker: "foo"
        }
      )
    end

    it 'should create an array of hashes from the AWS response' do
      resources = GeoEngineer::Resources::AwsRoute53Zone._fetch_remote_resources(nil)
      expect(resources.count).to eql(2)

      testzone = resources.first
      expect(testzone[:_terraform_id]).to eql('123')
      expect(testzone[:_geo_id]).to eql('testzone')
    end
  end
end
