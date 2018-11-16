class GeoEngineer::GPS::Nodes::TestNode < GeoEngineer::GPS::Node
  define_resource "aws_elb", :elb
  def json_schema
    {
      "type":  "object",
      "additionalProperties" => false,
      "properties":  {
        "name":  {
          "type":  "string",
          "default":  "default"
        }
      }
    }
  end

  def create_resources(project)
    create_elb(project)
  end
end
