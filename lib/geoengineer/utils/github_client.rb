########################################################################
# GithubClient exposes a set of API calls to fetch data from GitHub.
# The primary reason for centralizing them here is testing and stubbing.
########################################################################
class GithubClient
  Octokit.auto_paginate = true

  def self.organization_members(*args)
    Octokit.organization_members(*args).map(&:to_h)
  end

  def self.organization_repositories(*args)
    Octokit.organization_repositories(*args).map(&:to_h)
  end

  def self.organization_teams(*args)
    Octokit.organization_teams(*args).map(&:to_h)
  end

  def self.repository_collaborators(*args)
    Octokit.collaborators(*args).map(&:to_h)
  end

  def self.team_memberships(*args)
    Octokit.team_members(*args).map(&:to_h)
  end

  def self.team_repositories(*args)
    Octokit.team_repositories(*args).map(&:to_h)
  end
end
