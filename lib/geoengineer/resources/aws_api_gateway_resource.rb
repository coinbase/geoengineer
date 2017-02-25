########################################################################
# AwsCloudTrail is the +api_gatewat_rest_api+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/api_gateway_resource.html}
########################################################################
class GeoEngineer::Resources::AwsApiGatewayResource < GeoEngineer::Resource
  validate -> { validate_required_attributes([:rest_api_id, :parent_id, :path_part]) }

  after :initialize, -> { _terraform_id -> { nil } }
  after :initialize, -> { _geo_id -> { rand(36**20).to_s(36) } }

  def support_tags?
    false
  end
end

