require_relative "./api_gateway/helpers"

########################################################################
# AwsCloudTrail is the +aws_api_gateway_authorizer+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/aws_api_gateway_authorizer.html}
########################################################################
# TODO: not fully implemented
class GeoEngineer::Resources::AwsApiGatewayAuthorizer < GeoEngineer::Resource
  include GeoEngineer::ApiGatewayHelpers

  validate -> { validate_required_attributes([:authorizer_uri, :name, :rest_api_id]) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { name } }

  def support_tags?
    false
  end
end
