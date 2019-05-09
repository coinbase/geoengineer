########################################################################
# AwsDbInstance is the +aws_db_instance+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/db_instance.html Terraform Docs}
########################################################################
class GeoEngineer::Resources::AwsDbInstance < GeoEngineer::Resource
  validate -> {
    unless replicate_source_db
      validate_required_attributes(
        [
          :allocated_storage,
          :engine
        ]
      )
    end
  }
  validate -> {
    if new? && !(snapshot_identifier || replicate_source_db)
      validate_required_attributes([:password, :username, :name])
    end
  }
  validate -> { validate_required_attributes([:instance_class, :engine]) }
  validate -> { validate_subresource_required_attributes(:access_logs, [:bucket]) }

  after :initialize, -> { final_snapshot_identifier -> { "#{identifier}-final" } }
  after :initialize, -> { _terraform_id -> { identifier } }

  def to_terraform_state
    tfstate = super
    tfstate[:primary][:attributes] = {
      'identifier' => _terraform_id,
      'final_snapshot_identifier' => final_snapshot_identifier,
      'skip_final_snapshot' => 'true'
    }
    tfstate
  end

  def short_type
    "db"
  end

  def self._fetch_remote_resources(provider)
    dbs = _paginate(AwsClients.rds(provider).describe_db_instances, 'db_instances')
          .reject { |db| db.engine&.match?(/aurora/i) }

    dbs.map(&:to_h).map do |rds|
      rds[:_terraform_id] = rds[:db_instance_identifier]
      rds[:_geo_id]       = rds[:db_instance_identifier]
      rds[:identifier]    = rds[:db_instance_identifier]
      rds
    end
  end
end
