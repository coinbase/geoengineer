########################################################################
# AwsRdsCluster is the +aws_rds_cluster+ terraform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/rds_cluster.html}
########################################################################
class GeoEngineer::Resources::AwsRdsCluster < GeoEngineer::Resource
  validate -> {
    if new?
      validate_required_attributes([:database_name])
      unless snapshot_identifier
        validate_required_attributes([:master_password, :master_username])
      end
    end
  }

  after :initialize, -> { final_snapshot_identifier -> { "#{cluster_identifier}-final" } }
  after :initialize, -> { _terraform_id -> { cluster_identifier } }

  def to_terraform_state
    tfstate = super
    tfstate[:primary][:attributes] = {
      'cluster_identifier' => _terraform_id,
      'final_snapshot_identifier' => final_snapshot_identifier,
      'skip_final_snapshot' => 'true'
    }
    tfstate
  end

  def short_type
    'rds_cluster'
  end

  def self._fetch_remote_resources(provider)
    AwsClients.rds(provider).describe_db_clusters['db_clusters'].map(&:to_h).map do |rds|
      rds[:_terraform_id] = rds[:db_cluster_identifier]
      rds[:_geo_id]       = rds[:db_cluster_identifier]
      rds[:identifier]    = rds[:db_cluster_identifier]
      rds
    end
  end
end
