########################################################################
# AwsCloudTrail is the +aws_api_gateway_base_path_mapping+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/aws_api_gateway_base_path_mapping.html}
########################################################################
class GeoEngineer::Resources::AwsApiGatewayBasePathMapping < GeoEngineer::Resource
  validate -> { validate_required_attributes([:domain_name, :api_id]) }

  after :initialize, -> { _terraform_id -> { nil } }
  after :initialize, -> { _geo_id -> { rand(36**20).to_s(36) } }

  def support_tags?
    false
  end
end
