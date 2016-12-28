require_relative './spec_helper'

describe("GeoEngineer::Project") do
  class OutModuleTemplate < GeoEngineer::Template
    attr_reader :res1, :res2

    def initialize(name, project, parameters)
      super(name, project, parameters)

      res1 = resource('type', '1') {
        name "Resource1"
        param parameters[:res1]
      }

      res2 = resource('type', '2') {
        name "Resource2"
        rel  res1
      }

      @res1 = res1
      @res2 = res2
    end

    def template_resources
      [@res1, @res2]
    end
  end

  class GeoEngineer::Templates::InModuleTemplate < GeoEngineer::Template
  end

  describe 'validations' do
    it 'should validate its resources' do
      project = GeoEngineer::Project.new('org', "project_name", nil)
      project.environments = 'test'
      project.resource('res', 'id') {
        x 10
      }
      expect(project.errors.length).to eq 1 # geo_id nil
    end

    it 'should validate it has an environmnet' do
      project = GeoEngineer::Project.new('org', "project_name", nil)
      expect(project.errors.length).to eq 1
    end
  end

  describe '#from_template' do
    it 'should create a template from a class' do
      project = GeoEngineer::Project.new('org', "project_name", nil)
      temp1 = project.from_template('in_module_template', 'in')
      temp2 = project.from_template('out_module_template', 'out')
      expect(temp1.resources.length).to eq 0
      expect(temp2.resources.length).to eq 2
    end

    it 'should error if the template is not found' do
      project = GeoEngineer::Project.new('org', "project_name", nil)
      expect { project.from_template('not_a_template') }.to raise_error(StandardError)
    end
  end

  describe '#all_resources' do
    it 'should return all resources created in templates and directly' do
      project = GeoEngineer::Project.new('org', "project_name", nil)
      project.resource('res', 'id') { x 10 }
      project.from_template('out_module_template', 'out')
      expect(project.all_resources.length).to eq 3
    end
  end

  describe '#resource' do
    it 'should create a resource and assign itself as project' do
      project = GeoEngineer::Project.new('org', "project_name", nil)
      res = project.resource('res', 'id') { x 10 }
      expect(res.project).to eq project
    end
  end
end
