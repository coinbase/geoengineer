require_relative '../spec_helper'
require_relative '../helpers/api_gateway_helpers'

describe GeoEngineer::Resources::AwsApiGatewayRequestValidator do
  let(:aws_client) { AwsClients.api_gateway }
  before { aws_client.setup_stubbing }

  describe '._fetch_remote_resources' do
    it 'fetches the expected model resources' do
      # Stub the requests for retrieving the APIs and their resources
      ag = AwsClients.api_gateway
      create_api_with_resources(ag)

      # Create our request validator and stub the request to retrieve it
      validator1 = create_api_gateway_request_validator("v1")
      validator2 = create_api_gateway_request_validator("v2")
      ag.stub_responses(
        :get_request_validators,
        ag.stub_data(
          :get_request_validators,
          {
            items: [validator1, validator2]
          }
        )
      )

      validators = GeoEngineer::Resources::AwsApiGatewayRequestValidator._fetch_remote_resources(nil)
      expect(validators.size).to eq(2)

      # Verify that we get out what we're expecting
      expected_validator1 = validator1
      expected_validator1[:_geo_id] = 'TestAPI::v1'
      expected_validator1[:_terraform_id] = validator1[:id]
      expect(validators.first).to eq(expected_validator1)
    end
  end
end
