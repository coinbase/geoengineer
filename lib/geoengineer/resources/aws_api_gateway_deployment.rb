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

end
