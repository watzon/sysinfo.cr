module SysInfo
  class Network
    module Linux
      CtEntries       = 0
      CtSearched      = 1
      CtFound         = 2
      CtNew           = 3
      CtInvalid       = 4
      CtIgnore        = 5
      CtDelete        = 6
      CtDeleteList    = 7
      CtInsert        = 8
      CtInsertFailed  = 9
      CtDrop          = 10
      CtEarlyDrop     = 11
      CtIcmpError     = 12
      CtExpectNew     = 13
      CtExpectCreate  = 14
      CtExpectDelete  = 15
      CtSearchRestart = 16

      PROTOCOLS = {
        "ip",
        "icmp",
        "icmpmsg",
        "tcp",
        "udp",
        "udplite"
      }

      # NetIOCounters returnes network I/O statistics for every network
      # interface installed on the system.  If pernic argument is false,
      # return only sum of all information (which name is 'all'). If true,
      # every network interface installed on the system is returned
      # separately.
      def io_counters(per_nic = true)
        filename = File.join(Common::HOST_PROC, "net/dev")
        lines = File.read_lines(filename)

        stat_len = lines.size - 1

        nics = lines.reduce([] of IOCounterStat) do |acc, line|
          separator_pos = line.rindex(":")
          next acc unless separator_pos

          interface_name = line[0, separator_pos].strip
          next acc if interface_name.empty?

          fields = line[(separator_pos + 1)..].strip.split(/\s+/).map(&.to_u64)
          nic = IOCounterStat.new(
            name: interface_name,
            bytes_recv: fields[0],
            packets_recv: fields[1],
            errin: fields[2],
            dropin: fields[3],
            fifoin: fields[4],
            bytes_sent: fields[8],
            packets_sent: fields[9],
            errout: fields[10],
            dropout: fields[11],
            fifoout: fields[12],
          )

          acc << nic
          acc
        end

        unless per_nic
          # return get_io_counters_all(nics)
        end

        nics
      end

      def proto_counters(*protocols)
        if protocols.empty?
          protocols = PROTOCOLS
        end

        protocols = protocols.map(&.downcase)

        filename = File.join(Common::HOST_PROC, "net/snmp")
        lines = File.read_lines(filename)
        pairs = lines.in_groups_of(2)

        pairs.reduce([] of ProtoCountersStat) do |stats, (names_line, values_line)|
          next stats unless names_line && values_line

          proto, names = names_line.split(/\s*:\s*/)
          proto2, values = values_line.split(/\s*:\s*/)

          names = names.split(/\s+/)
          values = values.split(/\s+/).map(&.to_i64)

          if proto != proto2
            raise "#{filename} is not formatted correctly. Found mismatching row names #{proto} and #{proto2}"
          elsif names.size != values.size
            raise "#{filename} is not formatted correctly. Expected the same number of columns, got #{names.size}:#{values.size}."
          end

          proto = proto.downcase
          next stats unless protocols.includes?(proto)

          stat = ProtoCountersStat.new(
            protocol: proto,
            stats:  names.zip(values).to_h
          )

          stats << stat
          stats
        end
      end

      def filter_counters
        count_file = File.join(Common::HOST_PROC, "sys/net/netfilter/nf_conntrack_count")
        max_file = File.join(Common::HOST_PROC, "sys/net/netfilter/nf_conntrack_max")

        count = Common.read_ints(count_file)
        max = Common.read_ints(max_file)

        payload = FilterStat.new(
          conn_track_count: count[0],
          conn_track_max: max[0],
        )

        [payload]
      end

      def conntrack_stats(
        filename = File.join(Common::HOST_PROC, "net/stat/nf_conntrack"),
        per_cpu = true
      )
        lines = File.read_lines(filename)
        statlist = ConntrackStatList.new

        lines.each do |line|
          fields = line.strip.split(/\s+/)
          if fields.size == 17 && fields[0] != "entries"
            statlist.append(ConntrackStat.new(
              fields[CtEntries].to_u32(16),
              fields[CtSearched].to_u32(16),
              fields[CtFound].to_u32(16),
              fields[CtNew].to_u32(16),
              fields[CtInvalid].to_u32(16),
              fields[CtIgnore].to_u32(16),
              fields[CtDelete].to_u32(16),
              fields[CtDeleteList].to_u32(16),
              fields[CtInsert].to_u32(16),
              fields[CtInsertFailed].to_u32(16),
              fields[CtDrop].to_u32(16),
              fields[CtEarlyDrop].to_u32(16),
              fields[CtIcmpError].to_u32(16),
              fields[CtExpectNew].to_u32(16),
              fields[CtExpectCreate].to_u32(16),
              fields[CtExpectDelete].to_u32(16),
              fields[CtSearchRestart].to_u32(16)
            ))
          end
        end

        if per_cpu
          return statlist.items
        end

        statlist.summary
      end
    end
  end
end
