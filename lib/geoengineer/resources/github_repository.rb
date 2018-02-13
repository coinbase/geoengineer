################################################################################
# GithubRepository is the +github_repository+ Terraform resource.
#
# {https://www.terraform.io/docs/providers/github/r/repository.html Terraform Docs}
################################################################################
class GeoEngineer::Resources::GithubRepository < GeoEngineer::Resource
  validate -> { validate_required_attributes([:name]) }

  after :initialize, -> { _terraform_id -> { name } }
  after :initialize, -> { _geo_id -> { name } }

  def self._fetch_remote_resources(provider)
    repos = GithubClient.organization_repositories(provider.organization)

    repos.each do |repo|
      repo[:_terraform_id] = repo[:name]
      repo[:_geo_id] = repo[:name]
      repo[:homepage_url] = repo[:homepage]
      # TODO: Figure out how to get/set "allow_{rebase,squash,merge} commit
    end
  end
end
