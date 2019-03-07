require_relative '../spec_helper'
require_relative '../helpers/api_gateway_helpers'

describe GeoEngineer::Resources::AwsApiGatewayGatewayResponse do
  let(:aws_client) { AwsClients.api_gateway }
  before { aws_client.setup_stubbing }

  describe '._fetch_remote_resources' do
    it 'fetches the expected model resources' do
      # Stub the requests for retrieving the APIs and their resources
      ag = AwsClients.api_gateway
      create_api_with_resources(ag)

      # Create our request validator and stub the request to retrieve it
      response1 = create_api_gateway_gateway_response("BAD REQUEST BODY")
      response2 = create_api_gateway_gateway_response("EXPIRED TOKEN", { status_code: 403 })
      ag.stub_responses(
        :get_gateway_responses,
        ag.stub_data(
          :get_gateway_responses,
          {
            items: [response1, response2]
          }
        )
      )

      responses = GeoEngineer::Resources::AwsApiGatewayGatewayResponse._fetch_remote_resources(nil)
      expect(responses.size).to eq(2)

      # Verify that we get out what we're expecting
      expected_response1 = response1
      expected_response1[:_geo_id] = 'TestAPI::BAD REQUEST BODY'
      expected_response1[:_terraform_id] = response1[:id]
      expect(responses.first).to eq(expected_response1)
    end
  end
end
