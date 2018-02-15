module Sysinfo
  class CGroups
    class CGroupsException < Exception; end

    ATTRIBUTES = [
      "cpuset",
      "cpu",
      "cpuacct",
      "blkio",
      "memory",
      "devices",
      "freezer",
      "net_cls",
      "perf_event",
      "net_prio",
      "pids",
      "rdma"
    ]

    {% for attribute in ATTRIBUTES %}
      def self.{{ attribute.id }}
        data = File.read("/proc/cgroups")
        regex_match({{ attribute }}, data)
      rescue exception
        raise CGroupsException.new exception.message
      end
    {% end %}

    private def self.regex_match(attribute, data)
      regex = Regex.new("#{attribute}\\s+(.*?)\\s+(.*?)\\s+(.*?)\\s")
      if match = regex.match(data)
        return {
          hierarchy: match[1]? ? match[1].to_i : nil,
          num_cgroups: match[2]? ? match[2].to_i : nil,
          enabled: match[3]? ? match[3].to_i : nil
        }
      end
      { hierarchy: nil, num_cgroups: nil, enabled: nil }
    end

  end
end
