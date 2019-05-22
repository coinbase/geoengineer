###############################################################################################
# AwsDaxSubnetGroup is the +aws_dax_subnet_group+ Terraform resource.
#
# {https://www.terraform.io/docs/providers/aws/r/dax_subnet_group.html Terraform Docs}
##################################################################################################
class GeoEngineer::Resources::AwsDaxSubnetGroup < GeoEngineer::Resource
  validate -> { validate_required_attributes([:name, :subnet_ids]) }

  after :initialize, -> { _terraform_id -> { name } }
  after :initialize, -> { _geo_id -> { name } }

  def support_tags?
    false
  end

  def self._fetch_remote_resources(provider)
    subnet_groups = _paginate(AwsClients.dax(provider).describe_subnet_groups, 'subnet_groups')

    subnet_groups.map(&:to_h).map do |group|
      group[:name] = group[:subnet_group_name]
      group[:_terraform_id] = group[:subnet_group_name]
      group[:_geo_id] = group[:subnet_group_name]
      group
    end
  end
end
