########################################################################
# AwsCloudTrail is the +aws_api_gateway_api_key+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/aws_api_gateway_api_key.html}
########################################################################
class GeoEngineer::Resources::AwsApiGatewayApiKey < GeoEngineer::Resource
  validate -> { validate_required_attributes([:name]) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { name } }

  def support_tags?
    false
  end

  def self._fetch_remote_resources(provider)
    AwsClients.api_gateway(provider).get_api_keys['items'].map(&:to_h).map do |api|
      api[:_terraform_id] = api[:id]
      api[:_geo_id]       = api[:name]
      api
    end
  end
end
