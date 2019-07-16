################################################################################
# PostgresqlSchema is the postgresql_schema+ Terraform resource.
#
# {https://www.terraform.io/docs/providers/postgresql/r/postgresql_schema.html Terraform Docs}
################################################################################
class GeoEngineer::Resources::PostgresqlSchema < GeoEngineer::Resource
  validate -> { validate_required_attributes([:name]) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { name.to_s } }

  def support_tags?
    false
  end

  def self._fetch_remote_resources(provider)
    database_schemas = PostgresqlClient.database_schemas(provider)
    database_schemas.map { |schema| { _terraform_id: schema } }
  end
end
