########################################################################
# AwsCloudTrail is the +aws_api_gateway_domain_name+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/aws_api_gateway_domain_name.html}
########################################################################
class GeoEngineer::Resources::AwsApiGatewayDomainName < GeoEngineer::Resource
  include GeoEngineer::ApiGatewayHelpers

  validate -> {
    validate_required_attributes([
                                   :domain_name,
                                   :certificate_name,
                                   :certificate_body,
                                   :certificate_chain,
                                   :certificate_private_key
                                 ])
  }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { domain_name } }

  def support_tags?
    false
  end

  def self._fetch_remote_resources(provider)
    AwsClients.api_gateway(provider).get_domain_names['items'].map(&:to_h).map do |api|
      api[:_terraform_id] = api[:domain_name]
      api[:_geo_id]       = api[:domain_name]
      api
    end
  end
end
