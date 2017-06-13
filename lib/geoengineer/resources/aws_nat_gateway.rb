########################################################################
# AwsNatGateway is the +aws_nat_gateway+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/nat_gateway.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsNatGateway < GeoEngineer::Resource
  validate -> { validate_required_attributes([:subnet_id, :allocation_id]) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { "#{allocation_id}::#{subnet_id}" } }

  def support_tags?
    false
  end

  def self._fetch_remote_resources(provider)
    AwsClients.ec2(provider).describe_nat_gateways['nat_gateways'].map(&:to_h).map do |gateway|
      # AWS SDK has `nat_gateway_addresses` as an array, but you should only be able to
      # have exactly 1 elastic IP association. This logic should cover the bases...
      allocation = gateway[:nat_gateway_addresses].find { |addr| addr.key?(:allocation_id) }

      gateway.merge(
        {
          _terraform_id: gateway[:nat_gateway_id],
          _geo_id: "#{allocation[:allocation_id]}::#{gateway[:subnet_id]}"
        }
      )

      gateway
    end
  end
end
