require_relative '../spec_helper'

describe GeoEngineer::Resources::AwsApiGatewayMethod do
  let(:aws_client) { AwsClients.api_gateway }

  before { aws_client.setup_stubbing }
  common_resource_tests(described_class, described_class.type_from_class_name)
end
