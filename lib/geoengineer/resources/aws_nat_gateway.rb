########################################################################
# AwsNatGateway is the +aws_nat_gateway+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/nat_gateway.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsNatGateway < GeoEngineer::Resource
  validate -> { validate_required_attributes(%i(subnet_id allocation_id)) }
  validate -> { validate_has_tag(:Name) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { NullObject.maybe(tags)[:Name] } }

  def self._fetch_remote_resources(provider)
    AwsClients.ec2(provider).describe_nat_gateways['nat_gateways'].map(&:to_h).map do |gateway|
      gateway.merge(
        {
          _terraform_id: gateway[:nat_gateway_id],
          _geo_id: gateway[:tags]&.find { |tag| tag[:key] == "Name" }&.dig(:value)
        }
      )
    end
  end
end
