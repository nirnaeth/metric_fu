MetricFu.configure
module MetricFu
  class Run
    def initialize(options={})
      STDOUT.sync = true
      load_user_configuration
      disable_metrics(options)
    end
    def run
      run_reports
      save_reports
      save_graphs
      display_results
    end

    # ensure :hotspots runs last
    def report_metrics(metrics=MetricFu.metrics)
      MetricFu.configuration.metrics -= [ :hotspots ]
      MetricFu.configuration.metrics += [ :hotspots ]
      MetricFu.configuration.metrics
    end
    def run_reports
      report_metrics.each {|metric|
        mf_debug "** STARTING METRIC #{metric}"
        MetricFu.report.add(metric)
        mf_debug "** ENDING METRIC #{metric}"
      }
    end
    def save_reports
      mf_debug "** SAVING REPORT YAML OUTPUT TO #{MetricFu.base_directory}"
      MetricFu.report.save_output(MetricFu.report.as_yaml,
                                  MetricFu.base_directory,
                                  "report.yml")
      mf_debug "** SAVING REPORT DATA OUTPUT TO #{MetricFu.data_directory}"
      MetricFu.report.save_output(MetricFu.report.as_yaml,
                                  MetricFu.data_directory,
                                  "#{Time.now.strftime("%Y%m%d")}.yml")
      mf_debug "** SAVING TEMPLATIZED REPORT"
      MetricFu.report.save_templatized_report
    end
    def save_graphs
      mf_debug "** PREPARING TO GRAPH"
      MetricFu.graphs.each {|graph|
        mf_debug "** Graphing #{graph} with #{MetricFu.graph_engine}"
        MetricFu.graph.add(graph, MetricFu.graph_engine)
      }
      mf_debug "** GENERATING GRAPH"
      MetricFu.graph.generate
    end
    def display_results
      if MetricFu.report.open_in_browser?
        mf_debug "** OPENING IN BROWSER FROM #{MetricFu.output_directory}"
        MetricFu.report.show_in_browser(MetricFu.output_directory)
      end
    end
    private
    def load_user_configuration
      file = File.join(Dir.pwd, '.metrics')
      load file if File.exist?(file)
    end
    def disable_metrics(options)
      report_metrics.each do |metric|
        if options[metric.to_sym]
          mf_debug "using metric #{metric}"
        else
          mf_debug "disabling metric #{metric}"
          MetricFu.configuration.metrics -= [ metric ]
          MetricFu.configuration.graphs -= [ metric ]
          mf_debug "active metrics are #{MetricFu.configuration.metrics.inspect}"
        end
      end
    end
  end
end
