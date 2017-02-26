########################################################################
# AwsCloudTrail is the +api_gatewat_rest_api+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/api_gateway_integration_response.html}
########################################################################
class GeoEngineer::Resources::AwsApiGatewayIntegrationResponse < GeoEngineer::Resource
  validate -> {
    validate_required_attributes([
                                   :rest_api_id,
                                   :resource_id,
                                   :http_method,
                                   :status_code
                                 ])
  }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { rand(36**20).to_s(36) } }

  def support_tags?
    false
  end
end
