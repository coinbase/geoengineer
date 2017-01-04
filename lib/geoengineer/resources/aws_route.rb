########################################################################
# AwsRoute is the +aws_route+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/route.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsRoute < GeoEngineer::Resource
  validate -> { validate_required_attributes([:route_table_id, :destination_cidr_block]) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { "#{route_table_id}::#{destination_cidr_block}" } }

  def to_terraform_state
    tfstate = super
    tfstate[:primary][:attributes] = {
      'route_table_id' => route_table_id,
      'destination_cidr_block' => destination_cidr_block
    }
    tfstate
  end

  def support_tags?
    false
  end

  def self._fetch_remote_resources
    AwsClients
      .ec2
      .describe_route_tables['route_tables']
      .map(&:to_h)
      .map { |route_table| _extract_routes(route_table) }
      .flatten
      .compact
      .reject { |route| route[:gateway_id] == "local" }
      .reject { |route| route.key?(:destination_prefix_list_id) }
  end

  def self._extract_routes(route_table)
    route_table[:routes]&.map do |route|
      id = "r-#{route_table[:route_table_id]}#{Crc32.hashcode(route[:destination_cidr_block])}"
      route.merge(
        {
          route_table_id: route_table[:route_table_id],
          _terraform_id: id,
          _geo_id: "#{route_table[:route_table_id]}::#{route[:destination_cidr_block]}"
        }
      )
    end
  end
end
