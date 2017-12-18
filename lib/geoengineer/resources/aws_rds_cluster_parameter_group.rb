########################################################################
# AwsDbParameterGroup is the +aws_rds_cluster_parameter_group+ terraform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/db_parameter_group.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsRdsClusterParameterGroup < GeoEngineer::Resource
  validate -> { validate_required_attributes([:name, :family, :description]) }
  validate -> { validate_subresource_required_attributes(:parameter, [:name, :value]) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { name } }

  def short_type
    "rdspg"
  end

  def self._merge_ids(parameter_group)
    parameter_group.merge(
      {
        _terraform_id: parameter_group[:db_cluster_parameter_group_name],
        _geo_id: parameter_group[:db_cluster_parameter_group_name],
        name: parameter_group[:db_cluster_parameter_group_name]
      }
    )
  end

  def self._fetch_remote_resources(provider)
    AwsClients
      .rds(provider)
      .describe_db_cluster_parameter_groups['db_cluster_parameter_groups']
      .map(&:to_h)
      .map { |pg| _merge_ids(pg) }
  end
end
