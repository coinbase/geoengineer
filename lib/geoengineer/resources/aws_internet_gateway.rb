########################################################################
# AwsInternetGateway is the +aws_internet_gateway+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/internet_gateway.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsInternetGateway < GeoEngineer::Resource
  validate -> { validate_required_attributes([:vpc_id]) }
  validate -> { validate_has_tag(:Name) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { NullObject.maybe(tags)[:Name] } }

  def self._fetch_remote_resources
    AwsClients.ec2.describe_internet_gateways['internet_gateways'].map(&:to_h).map do |gateway|
      gateway.merge(
        {
          _terraform_id: gateway[:internet_gateway_id],
          _geo_id: gateway[:tags]&.find { |tag| tag[:key] == "Name" }&.dig(:value)
        }
      )
    end
  end
end
