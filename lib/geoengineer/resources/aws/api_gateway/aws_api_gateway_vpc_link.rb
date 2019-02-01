require_relative "./helpers"

########################################################################
# AwsApiGatewayVpcLink is the +api_gateway_vpc_link+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/aws_api_gateway_authorizer.html}
########################################################################
class GeoEngineer::Resources::AwsApiGatewayVpcLink < GeoEngineer::Resource
  include GeoEngineer::ApiGatewayHelpers

  validate -> { validate_required_attributes([:name, :target_arns]) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { name } }

  def self._fetch_remote_resources(provider)
    AwsClients.api_gateway(provider).get_vpc_links['items'].map(&:to_h).map do |api|
      api[:_terraform_id]    = api[:id]
      api[:_geo_id]          = api[:name]
      api
    end
  end

  def support_tags?
    false
  end
end
