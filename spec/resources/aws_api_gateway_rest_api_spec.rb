require_relative '../spec_helper'

describe GeoEngineer::Resources::AwsApiGatewayRestApi do
  let(:aws_client) { AwsClients.api_gateway }

  before { aws_client.setup_stubbing }
  common_resource_tests(described_class, described_class.type_from_class_name)

  describe "#_fetch_remote_resources" do
    before do
      aws_client.stub_responses(
        :get_rest_apis,
        {
          items:
          [
            {
              id: "test",
              name: "bob"
            }
          ]
        }
      )
    end

    it 'should create list of hashes from returned AWS SDK' do
      remote_resources = described_class._fetch_remote_resources(nil)
      expect(remote_resources.length).to eq 1
      expect(remote_resources[0][:_geo_id]).to eq "bob"
      expect(remote_resources[0][:_terraform_id]).to eq "test"
    end
  end
end
