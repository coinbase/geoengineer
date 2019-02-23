require_relative '../spec_helper'
require_relative '../helpers/api_gateway_helpers'

describe GeoEngineer::Resources::AwsApiGatewayModel do
  let(:aws_client) { AwsClients.api_gateway }
  before { aws_client.setup_stubbing }

  describe '._fetch_remote_resources' do
    it 'fetches the expected model resources' do
      # Stub the requests for retrieving the APIs and their resources
      ag = AwsClients.api_gateway
      create_api_with_resources(ag)

      # Create our API model and stub the request to retrieve it
      result_model = create_api_gateway_model("ResultModel")
      request_model = create_api_gateway_model("RequestModel")
      ag.stub_responses(
        :get_models,
        ag.stub_data(
          :get_models,
          {
            items: [result_model, request_model]
          }
        )
      )

      models = GeoEngineer::Resources::AwsApiGatewayModel._fetch_remote_resources(nil)
      expect(models.size).to eq(2)

      model_ids = models.map { |m| m[:id] }
      expect(model_ids).to include(result_model[:id])
      expect(model_ids).to include(request_model[:id])
    end
  end
end
