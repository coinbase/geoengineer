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

  def status_resource_rows(reses)
    rows = []
    rows << :separator
    rows << ['TerraformID', 'GeoID']
    rows << :separator
    reses.each do |sg|
      g_id = sg._geo_id
      g_id = "<<" if sg._terraform_id == sg._geo_id
      rows << [sg._terraform_id, g_id]
    end
    rows << :separator
    rows
  end

  def status_type_rows(type, codified, uncodified, stats)
    rows = []

    # Codified resources
    rows << [{ value: "### CODIFIED #{type} ###".colorize(:green), colspan: 2, alignment: :left }]
    rows.concat status_resource_rows(codified)

    # Uncodified resources
    rows << [{ value: "### UNCODIFIED #{type} ###".colorize(:red), colspan: 2, alignment: :left }]
    rows.concat status_resource_rows(uncodified)

    rows.concat status_rows(stats)
    puts Terminal::Table.new({ rows: rows })
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
      totals[:codified] += stats[:codified]
      totals[:uncodified] += stats[:uncodified]
      totals[:total] += stats[:total]
    end
    totals[:percent] = (100.0 * totals[:codified]) / totals[:total]
    totals
  end

  def status_rows(stats)
    rows = []
    rows << ['CODIFIED'.colorize(:green), stats[:codified]]
    rows << ['UNCODIFIED'.colorize(:red), stats[:uncodified]]
    rows << ['TOTAL'.colorize(:blue), stats[:total]]
    rows << ['PERCENT CODIFIED'.colorize({ mode: :bold }), format('%.2f%', stats[:percent])]
    rows
  end

  def status_action
    lambda do |args, options|
      type_stats = {}
      default_status_types.each do |type|
        codified = @environment.codified_resources(type)
        uncodified = @environment.uncodified_resources(type)
        type_stats[type] = calculate_type_status(codified, uncodified)
        status_type_rows(type, codified, uncodified, type_stats[type]) if @verbose
      end

      status = calculate_status(type_stats)
      puts Terminal::Table.new({ rows: status_rows(status) }) if @verbose
      puts JSON.pretty_generate(status)
    end
  end

  def status_cmd
    command :status do |c|
      c.syntax = 'geo status [<geo_files>]'
      c.description = 'Displays the the new, managed and unmanaged resources'
      action = status_action
      c.action init_action(:status, &action)
    end
  end
end
