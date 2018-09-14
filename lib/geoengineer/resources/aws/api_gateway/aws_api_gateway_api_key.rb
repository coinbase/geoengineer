require_relative "./helpers"

########################################################################
# AwsCloudTrail is the +aws_api_gateway_api_key+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/aws_api_gateway_api_key.html}
########################################################################
# TODO: not fully implemented
class GeoEngineer::Resources::AwsApiGatewayApiKey < GeoEngineer::Resource
  include GeoEngineer::ApiGatewayHelpers

  validate -> { validate_required_attributes([:name]) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { name } }

  def support_tags?
    false
  end
end
