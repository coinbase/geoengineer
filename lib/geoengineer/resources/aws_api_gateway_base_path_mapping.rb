########################################################################
# AwsCloudTrail is the +aws_api_gateway_base_path_mapping+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/aws_api_gateway_base_path_mapping.html}
########################################################################
class GeoEngineer::Resources::AwsApiGatewayBasePathMapping < GeoEngineer::Resource
  include GeoEngineer::ApiGatewayHelpers

  validate -> { validate_required_attributes([:domain_name, :rest_api_id]) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { domain_name } }

  def support_tags?
    false
  end

  def self._fetch_remote_resources(provider)
    AwsClients.api_gateway(provider).get_base_path_mappings['items'].map(&:to_h).map do |api|
      api[:_terraform_id] = api[:id]
      api[:_geo_id]       = api[:domain_name]
      api
    end
  end
end
