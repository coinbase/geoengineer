###############################################################################################
# AwsDbSubnetGroup is the +aws_db_subnet_group+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/db_subnet_group.html Terraform Docs}
##################################################################################################
class GeoEngineer::Resources::AwsDbSubnetGroup < GeoEngineer::Resource
  validate -> { validate_required_attributes([:name, :subnet_ids]) }

  after :initialize, -> { _terraform_id -> { name } }

  def support_tags?
    true
  end

  def self._fetch_remote_resources(provider)
    db_subnet_groups = AwsClients.rds(provider).describe_db_subnet_groups

    db_subnet_groups['db_subnet_groups'].map(&:to_h).map do |subnet_group|
      subnet_group[:name] = subnet_group[:db_subnet_group_name]
      subnet_group[:_terraform_id] = subnet_group[:db_subnet_group_name]
      subnet_group[:_geo_id] = subnet_group[:db_subnet_group_name]
      subnet_group
    end
  end
end
