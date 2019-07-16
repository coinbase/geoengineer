################################################################################
# PostgresqlRole is the postgresql_role+ Terraform resource.
#
# {https://www.terraform.io/docs/providers/postgresql/r/postgresql_role.html Terraform Docs}
################################################################################
class GeoEngineer::Resources::PostgresqlRole < GeoEngineer::Resource
  validate -> { validate_required_attributes([:name]) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { name.to_s } }

  def support_tags?
    false
  end

  def self._fetch_remote_resources(provider)
    database_roles = PostgresqlClient.database_roles(provider)
    database_roles.map { |role| { _terraform_id: role } }
  end
end
