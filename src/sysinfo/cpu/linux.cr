require "../common"

module SysInfo
  class CPU
    module Linux
      getter cpu_tick : Int32 = 100

      def init
        if getconf = Common.which("getconf")
          out = Common.command(getconf, "CLK_TCK")
          @cpu_tick = out.strip.to_i
        end
      rescue e
      end

      def times(per_cpu = true) : Array(TimesStat)
        filename = File.join(Common::HOST_PROC, "stat")
        lines = File.read_lines(filename)

        if per_cpu
          return [] of TimesStat if lines.size < 2
          lines = lines[1..].select(&.starts_with?("cpu"))
        else
          lines = lines[0..0]
        end

        lines.reduce([] of TimesStat) do |acc, line|
          val = parse_stat_line(line)
          acc << val if val
          acc
        end
      rescue e
        [] of TimesStat
      end

      def info : Array(InfoStat)
        filename = File.join(Common::HOST_PROC, "cpuinfo")
        file = File.read(filename)
        core_stats = file.split(/\n\n/)

        core_stats.reduce([] of InfoStat) do |stats, block|
          lines = block.split(/\n/)
          next stats if lines.size < 2
          hash = lines.map { |line| line.split(/\s?:\s?/).map(&.strip) }.to_h

          cpu = hash["processor"].to_i
          model_name = hash["Processor"]?
          vendor_id = hash["vendorId"]? || hash.fetch("vendor id", "")
          family = hash.fetch("cpu family", "")
          model = hash.fetch("model", "")

          model_name = hash.fetch("model name", "")
          if model_name.includes?("POWER8") || model_name.includes?("POWER7")
            model = model_name.split(" ").first
            family = "POWER"
            vendor_id = "IBM"
          end

          stepping = hash["revision"]? ? hash["revision"].split(".").first.to_i : hash["stepping"].to_i
          mhz = (hash["cpu MHz"]? || hash["clock"]?).try &.to_f? || 0.0
          cache_size = hash["cache size"].split(" ").first.to_i
          physical_id = hash.fetch("physical id", "")
          core_id = hash.fetch("core id", "")
          flags = hash.fetch("flags", "").split(/\s+|,/)
          microcode = hash.fetch("microcode", "")

          if core_id.empty?
            lines = File.read_lines(cpu_path(cpu, "topology/core_id"))
            core_id = lines[0].strip
          end

          # Override the value of mhz with cpufreq/cpuinfo_max_freq regardless
          # of the value from /proc/cpuinfo because we want to report the maximum
          # clock-speed of the CPU for mhz, matching the behaviour of Windows
          begin
            lines = File.read_lines(cpu_path(cpu, "cpufreq/cpuinfo_max_freq"))
            value = lines[0].strip.to_f
            mhz = value / 1000.0 # Value is in kHz
            if mhz > 9999
              mhz = mhz / 1000.0 # Value is in Hz
            end
          rescue e
            mhz = 0.0
          end

          stats << InfoStat.new(
            cpu: cpu,
            model_name: model_name,
            vendor_id: vendor_id,
            family: family,
            model: model,
            stepping: stepping,
            physical_id: physical_id,
            core_id: core_id,
            cores: 1,
            mhz: mhz,
            cache_size: cache_size,
            flags: flags,
            microcode: microcode
          )

          stats
        end
      end

      def counts(logical = true) : Int32
        # Logical cores
        if logical
          proc_cpuinfo = File.join(Common::HOST_PROC, "cpuinfo")
          lines = File.read_lines(proc_cpuinfo)

          ret = lines.reduce(0) do |i, line|
            line = line.downcase
            if line.starts_with?("processor")
              i += 1
            end
            i
          end

          if ret == 0
            proc_stat = File.join(Common::HOST_PROC, "stat")
            lines = File.read_lines(proc_stat)
            ret = lines.reduce(ret) do |i, line|
              if line.size > 4 && line.starts_with?("cpu") && '0' <= line[3] && line[3] <= '9'
                i += 1
              end
              i
            end
          end

          return ret
        end

        # Physical cores
        filename = File.join(Common::HOST_PROC, "cpuinfo")
        lines = File.read_lines(filename)

        mapping = {} of Int32 => Int32
        current_info = {} of String => Int32

        lines.each do |line|
          line = line.downcase.strip

          if line.empty?
            # New section
            id = current_info["physical id"]?
            cores = current_info["cpu cores"]?
            if id && cores
              mapping[id] = cores
            end
            current_info = current_info.clear
            next
          end

          fields = line.split(':').map(&.strip)

          if fields.size < 2
            next
          end

          if fields[0] == "physical id" || fields[0] == "cpu cores"
            val = fields[1].to_i?
            next unless val
            current_info[fields[0]] = val
          end
        end

        mapping.values.reduce(0) { |i, n| i += n }
      end

      private def cpu_path(cpu : Int32, relative_path : String = "")
        File.join(Common::HOST_SYS, "devices/system/cpu/cpu#{cpu}", relative_path)
      end

      private def parse_stat_line(line)
        return unless line.starts_with?("cpu")
        fields = line.split(/\s+/)

        cpu = fields[0] == "cpu" ? "cpu-total" : fields[0]
        user = fields[1].to_f64 / cpu_tick
        nice = fields[2].to_f64 / cpu_tick
        system = fields[3].to_f64 / cpu_tick
        idle = fields[4].to_f64 / cpu_tick
        iowait = fields[5].to_f64 / cpu_tick
        irq = fields[6].to_f64 / cpu_tick
        softirq = fields[7].to_f64 / cpu_tick
        steal = fields.size > 8 ? fields[8].to_f64 / cpu_tick : 0.0        # Linux >= 2.6.11
        guest = fields.size > 9 ? fields[9].to_f64 / cpu_tick : 0.0        # Linux >= 2.6.24
        guest_nice = fields.size > 10 ? fields[10].to_f64 / cpu_tick : 0.0 # Linux >= 3.2.0

        TimesStat.new(cpu, user, system, idle, nice, iowait, irq, softirq, steal, guest, guest_nice)
      end
    end
  end
end
