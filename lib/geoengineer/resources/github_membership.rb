################################################################################
# GithubMembership is the +github_membership+ Terraform resource.
#
# {https://www.terraform.io/docs/providers/github/r/membership.html Terraform Docs}
################################################################################
class GeoEngineer::Resources::GithubMembership < GeoEngineer::Resource
  validate -> { validate_required_attributes([:username]) }

  after :initialize, -> { _terraform_id -> { "#{fetch_provider.organization}:#{username}" } }
  after :initialize, -> { _geo_id -> { "#{fetch_provider.organization}:#{username}" } }

  def self._fetch_remote_resources(provider)
    # GitHub doesn't return the actual role of the member in the API, so we have
    # to make requests for each role to assign each set the appropriate role
    roles = %i[admin member]
    Parallel.map(roles, { in_threads: Parallel.processor_count }) do |member_role|
      members = GithubClient.organization_members(provider.organization, { role: member_role })

      members.each do |member|
        member[:_terraform_id] = "#{provider.organization}:#{member[:login]}"
        member[:_geo_id] = member[:_terraform_id]

        member[:username] = member[:login]
        member[:role] = member_role
      end
    end.flatten
  end
end
