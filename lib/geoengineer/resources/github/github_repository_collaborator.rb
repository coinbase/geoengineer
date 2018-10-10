################################################################################
# GithubRepositoryCollaborator is the +github_repository_collaborator+ Terraform
# resource.
#
# {https://www.terraform.io/docs/providers/github/r/repository_collaborator.html Terraform Docs}
################################################################################
class GeoEngineer::Resources::GithubRepositoryCollaborator < GeoEngineer::Resource
  validate -> { validate_required_attributes([:repository, :username]) }

  after :initialize, -> { _terraform_id -> { "#{repository}:#{username}" } }
  after :initialize, -> { _geo_id -> { "#{repository}:#{username}" } }

  def self._fetch_remote_resources(provider)
    repos = GithubClient.organization_repositories(provider.organization)

    Parallel.map(repos, { in_threads: Parallel.processor_count }) do |repo|
      collaborators_for_repo(repo)
    end.flatten
  end

  def self.collaborators_for_repo(repo)
    GithubClient.repository_collaborators(repo[:full_name]).each do |collab|
      collab[:_terraform_id] = "#{collab[:repository]}:#{collab[:login]}"
      collab[:_geo_id] = collab[:_terraform_id]

      collab[:username] = collab[:login]
      collab[:repository] = repo[:name]

      collab[:permission] =
        if collab[:permissions][:admin]
          'admin'
        elsif collab[:permissions][:push]
          'push'
        elsif collab[:permissions][:pull]
          'pull'
        end
    end
  end
end
