require_relative "./helpers"

########################################################################
# AwsApiGatewayBasePathMapping is the +aws_api_gateway_base_path_mapping+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/aws_api_gateway_base_path_mapping.html}
########################################################################
class GeoEngineer::Resources::AwsApiGatewayBasePathMapping < GeoEngineer::Resource
  include GeoEngineer::ApiGatewayHelpers

  validate -> { validate_required_attributes([:api_id, :stage_name]) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { "#{api_id}::#{stage_name}::#{base_path}" } }

  def self._fetch_remote_resources(provider)
    _fetch_remote_base_path_mappings(provider)
  end

  def support_tags?
    false
  end
end
