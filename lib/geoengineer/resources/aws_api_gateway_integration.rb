########################################################################
# AwsCloudTrail is the +api_gatewat_rest_api+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/api_gateway_integration.html}
########################################################################
class GeoEngineer::Resources::AwsApiGatewayIntegration < GeoEngineer::Resource
  validate -> { validate_required_attributes([
                  :rest_api_id,
                  :resource_id,
                  :http_method,
                  :type
              ]) }

  after :initialize, -> { _terraform_id -> { nil } }
  after :initialize, -> { _geo_id -> { rand(36**20).to_s(36) } }

  def support_tags?
    false
  end
end

