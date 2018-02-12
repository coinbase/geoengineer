################################################################################
# GithubIssueLabel is the +github_issue_label+ Terraform resource.
#
# {https://www.terraform.io/docs/providers/github/r/issue_label.html Terraform Docs}
################################################################################
class GeoEngineer::Resources::GithubIssueLabel < GeoEngineer::Resource
  validate -> { validate_required_attributes([:repository, :name, :color]) }

  after :initialize, -> { _terraform_id -> { "#{repository}:#{name}" } }
  after :initialize, -> { _geo_id -> { "#{repository}:#{name}" } }

  def self._fetch_remote_resources(provider)
    repos = GithubClient.organization_repositories(provider.organization)

    Parallel.map(repos, in_threads: Parallel.processor_count * 3) do |repo|
      labels = GithubClient.labels(repo[:full_name])
      labels.each do |label|
        label[:_terraform_id] = "#{repo[:name]}:#{label[:name]}"
        label[:_geo_id] = collab[:_terraform_id]

        label[:repository] = repo[:name]
      end
    end.flatten
  end
end
