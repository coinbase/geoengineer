########################################################################
# AwsCloudTrail is the +aws_api_gateway_client_certificate+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/aws_api_gateway_client_certificate.html}
########################################################################
# TODO: not fully implemented
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
end
