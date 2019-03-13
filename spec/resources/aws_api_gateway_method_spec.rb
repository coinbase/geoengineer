require_relative '../spec_helper'

describe GeoEngineer::Resources::AwsApiGatewayMethod do
  describe '#to_terraform_state' do
    it 'terraform state should not have an authorizer id key' do
      test_api = GeoEngineer::Resources::AwsApiGatewayRestApi.new("aws_api_gateway_rest_api", "test_api") {
        name "test"
      }

      test_resource = GeoEngineer::Resources::AwsApiGatewayResource.new("aws_api_gateway_resource", "test_resource") {
        _rest_api     test_api
        _parent       test_api.root_resource
        path_part     "test"
      }

      method = GeoEngineer::Resources::AwsApiGatewayMethod.new("aws_api_gateway_method", "test_method") {
        _rest_api     test_api
        _resource     test_resource
        http_method   "GET"
        authorization "NONE"
      }

      terraform_method = method.to_terraform_state
      expect(terraform_method[:primary][:attributes].key?("authorizer_id")).to be_falsey
    end

    it 'terraform state should have an authorizer id key' do
      test_api = GeoEngineer::Resources::AwsApiGatewayRestApi.new("aws_api_gateway_rest_api", "test_api") {
        name "test"
      }

      test_resource = GeoEngineer::Resources::AwsApiGatewayResource.new("aws_api_gateway_resource", "test_resource") {
        _rest_api     test_api
        _parent       test_api.root_resource
        path_part     "test"
      }

      test_authorizer = GeoEngineer::Resources::AwsApiGatewayAuthorizer.new("aws_api_gateway_authorizer", "test_auth") {
        name              "test_authorizer"
        _rest_api         test_api
        authorizer_uri    "https://test_url.com"
      }

      method = GeoEngineer::Resources::AwsApiGatewayMethod.new("aws_api_gateway_method", "test_method") {
        _rest_api     test_api
        _resource     test_resource
        http_method   "GET"
        authorization "CUSTOM"
        _authorizer   test_authorizer
      }

      terraform_method = method.to_terraform_state
      expect(terraform_method[:primary][:attributes].key?("authorizer_id")).to be_truthy
    end
  end
end
