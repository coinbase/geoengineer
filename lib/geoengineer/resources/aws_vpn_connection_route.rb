########################################################################
# AwsVpnConnectionRoute is the +aws_vpn_connection+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/vpn_connection_route.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsVpnConnectionRoute < GeoEngineer::Resource
  validate -> { validate_required_attributes([:destination_cidr_block, :vpn_connection_id]) }

  after :initialize, -> { _terraform_id -> { "#{destination_cidr_block}:#{vpn_connection_id}" } }

  def support_tags?
    false
  end

  def self._fetch_remote_resources(provider)
    AwsClients
      .ec2(provider)
      .describe_vpn_connections['vpn_connections']
      .map(&:to_h)
      .select { |connection| !connection[:routes].empty? }
      .map { |connection| _generate_routes(connection) }
      .flatten
  end

  def self._generate_routes(connection)
    connection[:routes].map do |route|
      route.merge(
        {
          _terraform_id: "#{route[:destination_cidr_block]}:#{connection[:vpn_connection_id]}",
          vpn_connection_id: connection[:vpn_connection_id]
        }
      )
    end
  end
end
