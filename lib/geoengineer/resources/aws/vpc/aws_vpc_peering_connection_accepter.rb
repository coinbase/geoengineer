########################################################################
# AwsVpcPeeringConnection is the +aws_vpc_peering_connection_Accepter+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/vpc_peering_accepter.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsVpcPeeringConnectionAccepter < GeoEngineer::Resource
  validate -> { validate_required_attributes([:vpc_peering_connection_id]) }
  validate -> { validate_has_tag(:Name) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { vpc_peering_connection_id } }

  def to_terraform_state
    tfstate = super
    tfstate[:primary][:attributes] = {
      'id' => vpc_peering_connection_id,
      'vpc_peering_connection_id' => vpc_peering_connection_id
    }
    tfstate
  end

  def self._fetch_remote_resources(provider)
    AwsClients
      .ec2(provider)
      .describe_vpc_peering_connections['vpc_peering_connections']
      .map(&:to_h)
      .map { |connection| _merge_ids(connection) }
  end

  def self._merge_ids(connection)
    connection.merge(
      {
        _terraform_id: connection[:vpc_peering_connection_id],
        _geo_id: connection[:vpc_peering_connection_id]
      }
    )
  end
end
