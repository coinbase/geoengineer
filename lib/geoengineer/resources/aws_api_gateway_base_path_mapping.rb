require_relative "./api_gateway/helpers"

########################################################################
# AwsCloudTrail is the +aws_api_gateway_base_path_mapping+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/aws_api_gateway_base_path_mapping.html}
########################################################################
# TODO: not fully implemented
class GeoEngineer::Resources::AwsApiGatewayBasePathMapping < GeoEngineer::Resource
  include GeoEngineer::ApiGatewayHelpers

  validate -> { validate_required_attributes([:domain_name, :rest_api_id]) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { domain_name } }

  def support_tags?
    false
  end
end
