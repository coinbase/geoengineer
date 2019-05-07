require_relative "./helpers"

########################################################################
# AwsApiGatewayDomainName is the +aws_api_gateway_domain_name+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/aws_api_gateway_domain_name.html}
########################################################################
class GeoEngineer::Resources::AwsApiGatewayDomainName < GeoEngineer::Resource
  include GeoEngineer::ApiGatewayHelpers

  validate -> {
    validate_required_attributes([
                                   :domain_name
                                 ])
  }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { domain_name } }

  def self._fetch_remote_resources(provider)
    _fetch_remote_domain_names(provider)
  end

  def support_tags?
    false
  end
end
