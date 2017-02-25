########################################################################
# AwsCloudTrail is the +aws_api_gateway_api_key+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/aws_api_gateway_api_key.html}
########################################################################
class GeoEngineer::Resources::AwsApiGatewayApiKey < GeoEngineer::Resource
  validate -> { validate_required_attributes([:name]) }

  after :initialize, -> { _terraform_id -> { nil } }
  after :initialize, -> { _geo_id -> { rand(36**20).to_s(36) } }

  def support_tags?
    false
  end
end
