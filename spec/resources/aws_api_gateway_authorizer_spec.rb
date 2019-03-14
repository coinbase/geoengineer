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

  describe '#to_terraform_state' do
    it 'includes an authorizer_uri key to terraform state if it is correctly specified' do
      test_api = GeoEngineer::Resources::AwsApiGatewayRestApi.new("aws_api_gateway_rest_api", "test_api") {
        name "test"
      }

      test_authorizer = GeoEngineer::Resources::AwsApiGatewayAuthorizer.new("aws_api_gateway_authorizer", "test_auth") {
        name              "test_authorizer"
        _rest_api         test_api
        type              "REQUEST"
        authorizer_uri    "https://test_url.com"
      }

      terraform_auth = test_authorizer.to_terraform_state
      expect(terraform_auth[:primary][:attributes].key?("authorizer_uri")).to be_truthy
    end

    it 'does not include an authorizer_uri key if not specified' do
      test_api = GeoEngineer::Resources::AwsApiGatewayRestApi.new("aws_api_gateway_rest_api", "test_api") {
        name "test"
      }

      test_authorizer = GeoEngineer::Resources::AwsApiGatewayAuthorizer.new("aws_api_gateway_authorizer", "test_auth") {
        name              "test_authorizer"
        _rest_api         test_api
        type              "COGNITO_USER_POOLS"
      }

      terraform_auth = test_authorizer.to_terraform_state
      expect(terraform_auth[:primary][:attributes].key?("authorizer_uri")).to be_falsey
    end
  end
end
