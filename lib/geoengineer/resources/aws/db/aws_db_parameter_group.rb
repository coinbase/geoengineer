########################################################################
# AwsDbParameterGroup is the +aws_db_parameter_group+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/db_parameter_group.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsDbParameterGroup < GeoEngineer::Resource
  validate -> { validate_required_attributes([:name, :family, :description]) }
  validate -> { validate_subresource_required_attributes(:parameter, [:name, :value]) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { name } }

  def short_type
    "dbpg"
  end

  def self._fetch_remote_resources(provider)
    AwsClients.rds(provider)
              .describe_db_parameter_groups['db_parameter_groups']
              .map(&:to_h).map do |pg|
      pg[:_terraform_id] = pg[:db_parameter_group_name]
      pg[:_geo_id] = pg[:db_parameter_group_name]
      pg[:name] = pg[:db_parameter_group_name]
      pg
    end
  end
end
