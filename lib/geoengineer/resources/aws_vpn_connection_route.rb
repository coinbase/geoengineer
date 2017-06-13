########################################################################
# AwsVpnConnectionRoute is the +aws_vpn_connection+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/vpn_connection_route.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsVpnConnectionRoute < GeoEngineer::Resource
  validate -> { validate_required_attributes([:destination_cidr_block, :vpn_connection_id]) }

  after :initialize, -> {
    _terraform_id -> {
      connection_route_id unless terraform_ref?
    }
  }

  after :initialize, -> {
    _geo_id -> {
      connection_route_id
    }
  }

  # Is the VPN connection id a terraform ref or an id
  def terraform_ref?
    /^\${[a-zA-Z0-9\._-]+}$/.match(vpn_connection_id)
  end

  def connection_route_id
    self.class.build_connection_route_id(
      destination_cidr_block,
      vpn_connection_id
    )
  end

  def self.build_connection_route_id(cidr, connection_id)
    "#{cidr}:#{connection_id}"
  end

  def support_tags?
    false
  end

  def self._fetch_remote_resources(provider)
    AwsClients.ec2(provider)
              .describe_vpn_connections['vpn_connections']
              .map(&:to_h)
              .select { |connection| !connection[:routes].empty? }
              .map { |connection| _generate_routes(connection) }
              .flatten
  end

  def self._generate_routes(connection)
    connection[:routes].map do |route|
      cidr = route[:destination_cidr_block]
      connection_id = route[:vpn_connection_id]

      id = build_connection_route_id(cidr, connection_id)

      route.merge({ _terraform_id: id, _geo_id: id })
    end
  end
end
