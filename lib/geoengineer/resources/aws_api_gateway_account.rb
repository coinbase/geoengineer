########################################################################
# AwsCloudTrail is the +api_gatewat_rest_api+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/api_gateway_account.html}
########################################################################
class GeoEngineer::Resources::AwsApiGatewayAccount < GeoEngineer::Resource
  after :initialize, -> { _terraform_id -> { nil } }
  after :initialize, -> { _geo_id -> { rand(36**20).to_s(36) } }

  def support_tags?
    false
  end

  # TODO only get account is visible
  # def self._fetch_remote_resources(provider)
  #   AwsClients.api_gateway(provider)
  # end
end
