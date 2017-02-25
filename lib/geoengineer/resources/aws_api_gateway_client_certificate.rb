########################################################################
# AwsCloudTrail is the +aws_api_gateway_client_certificate+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/aws_api_gateway_client_certificate.html}
########################################################################
class GeoEngineer::Resources::AwsApiGatewayClientCertificate < GeoEngineer::Resource

  after :initialize, -> { _terraform_id -> { nil } }
  after :initialize, -> { _geo_id -> { rand(36**20).to_s(36) } }

  def support_tags?
    false
  end
end
