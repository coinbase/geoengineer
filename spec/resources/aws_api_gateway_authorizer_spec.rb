require_relative '../spec_helper'
require_relative '../helpers/api_gateway_helpers'

describe GeoEngineer::Resources::AwsApiGatewayAuthorizer do
  let(:aws_client) { AwsClients.api_gateway }
  before { aws_client.setup_stubbing }

  describe '._fetch_remote_resources' do
    it 'fetches the expected model resources' do
      # Stub the requests for retrieving the APIs and their resources
      ag = AwsClients.api_gateway
      create_api_with_resources(ag)

      # Create our request validator and stub the request to retrieve it
      authorizer1 = create_api_gateway_authorizer("authorizer1")
      authorizer2 = create_api_gateway_authorizer("authorizer2")
      ag.stub_responses(
        :get_authorizers,
        ag.stub_data(
          :get_authorizers,
          {
            items: [authorizer1, authorizer2]
          }
        )
      )

      authorizers = GeoEngineer::Resources::AwsApiGatewayAuthorizer._fetch_remote_resources(nil)
      expect(authorizers.size).to eq(2)

      # Verify that we get out what we're expecting
      expected_authorizer1 = authorizer1
      expected_authorizer1[:_geo_id] = 'TestAPI::authorizer1'
      expected_authorizer1[:_terraform_id] = authorizer1[:id]
      expect(authorizers.first).to eq(expected_authorizer1)
    end
  end
end
