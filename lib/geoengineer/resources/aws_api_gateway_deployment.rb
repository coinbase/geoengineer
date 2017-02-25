########################################################################
# AwsCloudTrail is the +api_gateway_deployment+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/api_gateway_deployment.html}
########################################################################
class GeoEngineer::Resources::AwsApiGatewayDeployment < GeoEngineer::Resource
  validate -> { validate_required_attributes([
                  :rest_api_id,
                  :stage_name
              ]) }

  after :initialize, -> { _terraform_id -> { nil } }
  after :initialize, -> { _geo_id -> { rand(36**20).to_s(36) } }

  def support_tags?
    false
  end
end
