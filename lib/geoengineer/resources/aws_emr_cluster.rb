########################################################################
# AwsEmr is the +aws_emr_cluster+ terrform resource,
#
# {https://www.terraform.io/docs/providers/aws/r/emr_cluster.html}
########################################################################
class GeoEngineer::Resources::AwsEmrCluster < GeoEngineer::Resource
  TERMINATED_CLUSTER_STATES = %w(TERMINATING TERMINATED TERMINATED_WITH_ERRORS).freeze

  validate -> { validate_required_attributes([:name]) }
  validate -> { validate_has_tag(:Name) }

  after :initialize, -> { _terraform_id -> { NullObject.maybe(remote_resource)._terraform_id } }
  after :initialize, -> { _geo_id -> { name } }

  def self._fetch_remote_resources(provider)
    clusters = AwsClients.emr(provider).list_clusters['clusters'].map(&:to_h).map do |cluster|
      cluster[:_terraform_id] = cluster[:id]
      cluster[:_geo_id] = cluster[:name]
      cluster
    end

    # AWS allows you to create multiple clusters with the same name if the
    # existing cluster is already terminated. Filter them out
    clusters.reject do |cluster|
      TERMINATED_CLUSTER_STATES.include?(cluster.fetch(:status, {})[:state])
    end
  end
end
