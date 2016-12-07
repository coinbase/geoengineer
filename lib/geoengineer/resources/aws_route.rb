########################################################################
# AwsRoute is the +aws_route+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/route.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsRoute < GeoEngineer::Resource
  validate -> { validate_required_attributes([:route_table_id, :destination_cidr_block]) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { "#{route_table_id}|#{destination_cidr_block}" } }

  def self._fetch_remote_resources
    AwsClients
      .ec2
      .describe_route_tables['route_tables']
      .map(&:to_h)
      .map { |route_table| route_table[:routes] }
      .flatten
      .compact
      .map { |route| _merge_ids(route) }
  end

  def self._merge_ids(route)
    terraform_id = "r-#{route[:route_table_id]}#{Crc32.hashcode(route[:destination_cidr_block])}"
    route.merge(
      {
        _terraform_id: terraform_id,
        _geo_id: "#{route[:route_table_id]}|#{route[:destination_cidr_block]}"
      }
    )
  end
end
