########################################################################
# AwsRedshiftCluster is the +aws_redshift_cluster+ terrform resource,
#
# Terraform Docs
# {https://www.terraform.io/docs/providers/aws/r/redshift_cluster.html#cluster_version}
########################################################################
class GeoEngineer::Resources::AwsRedshiftCluster < GeoEngineer::Resource
  validate -> { validate_required_attributes([:cluster_identifier, :node_type]) }
  validate -> {
    if new? && !snapshot_identifier
      validate_required_attributes([:master_password, :master_username])
    end
  }
  validate -> {
    validate_required_attributes([:number_of_nodes]) if self.cluster_type == 'multi-node'
  }
  validate -> { validate_required_attributes([:bucket_name]) if self.enable_logging }

  after :initialize, -> { _terraform_id -> { cluster_identifier } }

  def self._fetch_remote_resources
    AwsClients
      .redshift
      .describe_clusters
      .clusters
      .map(&:to_h)
      .map { |cluster| cluster.merge({ _terraform_id: cluster[:cluster_identifier] }) }
  end
end
