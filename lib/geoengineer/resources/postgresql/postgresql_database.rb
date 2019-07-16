################################################################################
# PostgresqlDatabase is the postgresql_database+ Terraform resource.
#
# {https://www.terraform.io/docs/providers/postgresql/r/postgresql_database.html Terraform Docs}
################################################################################
class GeoEngineer::Resources::PostgresqlDatabase < GeoEngineer::Resource
  validate -> { validate_required_attributes([:name]) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { name.to_s } }

  def support_tags?
    false
  end

  def self._fetch_remote_resources(provider)
    database_names = PostgresqlClient.database_names(provider)
    database_names.map { |name| { _terraform_id: name } }
  end
end
