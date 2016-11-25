require_relative './spec_helper'

describe("GeoEngineer::Template") do
  class CustomTemplate < GeoEngineer::Template
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

  it 'should be extendable' do
    project = NullObject.new
    template = CustomTemplate.new("custom_template", project, { res1: "Res1" })

    expect(template.res1.name).to eq "Resource1"
    expect(template.res1.param).to eq "Res1"

    expect(template.res2.name).to eq "Resource2"
    expect(template.res2.rel).to eq template.res1
  end
end
