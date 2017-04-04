########################################################################
# AwsCloudTrail is the +aws_api_gateway_client_certificate+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/aws_api_gateway_client_certificate.html}
########################################################################
class GeoEngineer::Resources::AwsApiGatewayClientCertificate < GeoEngineer::Resource
  include GeoEngineer::ApiGatewayHelpers

  validate -> {
    validate_required_attributes([
                                   :description
                                 ])
  }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { description } }

  def support_tags?
    false
  end

  def self._fetch_remote_resources(provider)
    AwsClients.api_gateway(provider).get_client_certificates['items'].map(&:to_h).map do |api|
      api[:_terraform_id] = api[:client_certificate_id]
      api[:_geo_id]       = api[:description]
      api
    end
  end
end
