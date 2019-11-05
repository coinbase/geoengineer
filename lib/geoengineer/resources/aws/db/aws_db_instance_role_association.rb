########################################################################
# AwsDbInstanceRoleAssociation is the +aws_db_instance_role_association+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/db_instance_role_association.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsDbInstanceRoleAssociation < GeoEngineer::Resource
  validate -> { validate_required_attributes([:db_instance_identifier, :feature_name, :role_arn]) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { "#{db_instance_identifier},#{feature_name}" } }

  def self._fetch_remote_resources(provider)
    instances = _paginate(AwsClients.rds(provider).describe_db_instances, 'db_instances')

    instances.map.flat_map do |instance|
      identifier = instance.db_instance_identifier
      instance.associated_roles.map(&:to_h).map do |role|
        role[:_terraform_id] = "#{identifier},#{role[:role_arn]}"
        role[:_geo_id] = "#{identifier},#{role[:feature_name]}"
        role
      end
    end
  end
end
