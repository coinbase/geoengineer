########################################################################
# AwsCloudTrail is the +aws_api_gateway_authorizer+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/aws_api_gateway_authorizer.html}
########################################################################
class GeoEngineer::Resources::AwsApiGatewayauthorizer < GeoEngineer::Resource
  validate -> { validate_required_attributes([:authorizer_uri, :name, :rest_api_id]) }

  after :initialize, -> { _terraform_id -> { nil } }
  after :initialize, -> { _geo_id -> { rand(36**20).to_s(36) } }

  def support_tags?
    false
  end
end
