# Status Command for Geo
module GeoCLI::StatusCommand
  def calculate_type_status(codified, uncodified)
    total = codified.count + uncodified.count
    {
      codified: codified.count,
      uncodified: uncodified.count,
      total: total,
      percent: (100.0 * codified.count) / total
    }
  end

  def resource_id_array(resources)
    resources
      .select { |r| !r.attributes.empty? }
      .map { |r| r._geo_id || r._terraform_id }
  end

  def status_types(options)
    return options.resources.split(',') if options.resources
    environment.status_types ? environment.status_types : default_status_types
  end

  def default_status_types
    [
      "aws_security_group",
      "aws_elb",
      "aws_db_instance",
      "aws_elasticache_cluster",
      "aws_s3_bucket",
      "aws_sqs_queue"
    ]
  end

  def calculate_status(type_stats)
    totals = {
      codified: 0,
      uncodified: 0,
      total: 0
    }
    type_stats.each do |type, stats|
      totals[:codified] += stats[:stats][:codified]
      totals[:uncodified] += stats[:stats][:uncodified]
      totals[:total] += stats[:stats][:total]
    end
    totals[:percent] = (100.0 * totals[:codified]) / totals[:total]
    totals
  end

  def report_json(type_stats, status)
    status[:resources] = {}
    type_stats.each do |type, resources|
      status[:resources][type] = {}
      status[:resources][type][:uncodified] = resource_id_array(resources[:uncodified])
      status[:resources][type][:codified] = resource_id_array(resources[:codified])
    end
    status
  end

  def type_stats(options)
    type_stats = {}
    status_types(options).each do |type|
      type_stats[type] = {}
      type_stats[type][:codified] = @environment.codified_resources(type)
      type_stats[type][:uncodified] = @environment.uncodified_resources(type)
      type_stats[type][:stats] = calculate_type_status(
        type_stats[type][:codified],
        type_stats[type][:uncodified]
      )
    end
    type_stats
  end

  def status_action
    lambda do |args, options|
      type_stats = type_stats(options)
      status = calculate_status(type_stats)
      puts JSON.pretty_generate(report_json(type_stats, status))
    end
  end

  def status_cmd
    command :status do |c|
      c.syntax = 'geo status [<geo_files>]'
      c.description = 'Displays the the new, managed and unmanaged resources'
      c.option '--resources COMMA SEPERATED STRING', String, 'select resources for statuses'
      action = status_action
      c.action init_action(:status, &action)
    end
  end
end
