########################################################################
# AwsRdsClusterEndpoint is the +aws_rds_cluster_endpoint+ terraform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/rds_cluster_endpoint.html}
########################################################################
class GeoEngineer::Resources::AwsRdsClusterEndpoint < GeoEngineer::Resource
  validate -> {
    validate_required_attributes(
      [
        :cluster_identifier,
        :cluster_endpoint_identifier,
        :custom_endpoint_type
      ]
    )
  }

  after :initialize, -> { _terraform_id -> { cluster_identifier } }

  def to_terraform_state
    tfstate = super
    tfstate[:primary][:attributes] = {
      'cluster_identifier' => _terraform_id
    }
    tfstate
  end

  def short_type
    'rds_cluster_endpoint'
  end

  def support_tags?
    false
  end

  def self._fetch_remote_resources(provider)
    AwsClients.rds(provider).describe_db_cluster_endpoints['db_cluster_endpoints'].map(&:to_h).map do |endpoint|
      endpoint[:_terraform_id] = endpoint[:db_cluster_identifier]
      endpoint[:_geo_id] = endpoint[:db_cluster_identifier]
      endpoint[:cluster_identifier] = endpoint[:db_cluster_identifier]
      endpoint
    end
  end
end
