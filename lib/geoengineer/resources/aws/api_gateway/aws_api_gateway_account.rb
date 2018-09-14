require_relative "./helpers"

########################################################################
# AwsCloudTrail is the +api_gatewat_rest_api+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/api_gateway_account.html}
########################################################################
# TODO: not fully implemented
class GeoEngineer::Resources::AwsApiGatewayAccount < GeoEngineer::Resource
  include GeoEngineer::ApiGatewayHelpers

  after :initialize, -> { _terraform_id -> { nil } }
  after :initialize, -> { _geo_id -> { rand(36**20).to_s(36) } }

  def support_tags?
    false
  end
end
