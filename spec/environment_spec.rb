require_relative './spec_helper'

describe("GeoEngineer::Environment") do
  describe 'validations' do
    it 'should have unique terrform id' do
      env = GeoEngineer::Environment.new("test") {
        region "us-west-1"
        account_id 1
      }
      env.resource('type', 'id1') {
        _terraform_id "tid"
        _geo_id 'gid1'
      }
      env.resource('type', 'id2') {
        _terraform_id "tid"
        _geo_id 'gid2'
      }
      expect(env.all_resources.length).to eq 2
      expect(env.errors.length).to eq 1
    end

    it 'should have unique geo_id' do
      env = GeoEngineer::Environment.new("test") {
        region "us-west-1"
        account_id 1
      }
      env.resource('type', 'id1') {
        _terraform_id "tid1"
        _geo_id 'gid'
      }
      env.resource('type', 'id2') {
        _terraform_id "tid2"
        _geo_id 'gid'
      }
      expect(env.all_resources.length).to eq 2
      expect(env.errors.length).to eq 1
    end

    it 'should have unique type and ids' do
      env = GeoEngineer::Environment.new("test") {
        region "us-west-1"
        account_id 1
      }
      env.resource('type', 'id1') {
        _terraform_id "tid1"
        _geo_id 'gid1'
      }
      env.resource('type', 'id1') {
        _terraform_id "tid2"
        _geo_id 'gid2'
      }
      expect(env.all_resources.length).to eq 2
      expect(env.errors.length).to eq 1
    end
  end

  describe '#codifies_resources' do
    it 'should return both codified and uncodified resources' do
      class GeoEngineer::Resources::CodifiedResource < GeoEngineer::Resource
        def self._fetch_remote_resources
          [{ _geo_id: "geo_id1" }, { _geo_id: "geo_id2" }]
        end
      end

      env = GeoEngineer::Environment.new("test")
      env.resource('codified_resource', 'id1') {
        _terraform_id "geo_id1"
      }

      expect(env.codified_resources('codified_resource').length).to eq 1
      expect(env.uncodified_resources('codified_resource').length).to eq 1
    end
  end

  describe '#to_terraform_state' do
    it 'should return state of resources' do
      env = GeoEngineer::Environment.new("test")
      env.resource('type', 'id1') {
        _terraform_id "tid"
        _geo_id 'gid1'
      }
      tfstate = env.to_terraform_state
      expect(tfstate[:modules].first[:resources].length).to eq 1
    end
  end

  describe '#to_terraform_json' do
    it 'should return terraform of all resources' do
      env = GeoEngineer::Environment.new("test")
      env.resource('type', 'id1') {
        _terraform_id "tid"
        _geo_id 'gid1'
      }
      tfjson = env.to_terraform_json
      expect(tfjson[:resource].length).to eq 1
    end
  end

  describe '#project' do
    it 'should create a project with this as environment' do
      env = GeoEngineer::Environment.new("test")
      env.project("org", "name") {
        environments 'test'
      }
      expect(env.projects.length).to eq 1
    end

    it 'should only load projects in the environment' do
      env = GeoEngineer::Environment.new("test")
      p0 = env.project("org", "0") {
        environments 'test'
      }

      p1 = env.project("org", "1") {
        environments 'nottest'
      }

      expect(p0.class).to eq GeoEngineer::Project
      expect(p1.class).to eq NullObject
    end
  end

  describe '#all_resources' do
    it 'should include local and project resources (if project in env)' do
      env = GeoEngineer::Environment.new("test")
      env.resource('type', 'id0') { x 2 }

      p0 = env.project("org", "0") {
        environments 'test'
      }
      p0.resource('type', 'id1') { x 2 }

      p1 = env.project("org", "1") {
        environments 'nottest'
      }
      p1.resource('type', 'id2') { x 2 }

      expect(env.all_resources.length).to eq 2
    end
  end
end
