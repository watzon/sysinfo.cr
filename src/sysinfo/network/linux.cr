module SysInfo
  class Network
    module Linux
      KindTCP4 = NetConnectionKindType.new(
        family: AF_INET.to_u32,
        sock_type: SOCK_STREAM.to_u32,
        filename: "tcp"
      )

      KindTCP6 = NetConnectionKindType.new(
        family: AF_INET6.to_u32,
        sock_type: SOCK_STREAM.to_u32,
        filename: "tcp6"
      )

      KindUDP4 = NetConnectionKindType.new(
        family: AF_INET.to_u32,
        sock_type: SOCK_DGRAM.to_u32,
        filename: "udp"
      )

      KindUDP6 = NetConnectionKindType.new(
        family: AF_INET6.to_u32,
        sock_type: SOCK_DGRAM.to_u32,
        filename: "udp6"
      )

      KindUNIX = NetConnectionKindType.new(
        family: AF_UNIX.to_u32,
        sock_type: 0_u32,
        filename: "unix"
      )

      ConnectionsKinds = {
        all:    [KindTCP4, KindTCP6, KindUDP4, KindUDP6, KindUNIX],
        tcp:    [KindTCP4, KindTCP6],
        tcp4:   [KindTCP4],
        tcp6:   [KindTCP6],
        udp:    [KindUDP4, KindUDP6],
        udp4:   [KindUDP4],
        udp6:   [KindUDP6],
        unix:   [KindUNIX],
        inet:   [KindTCP4, KindTCP6, KindUDP4, KindUDP6],
        inet4:  [KindTCP4, KindUDP4],
        inet6:  [KindTCP6, KindUDP6]
      }

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

      TCP_STATUSES = {
        "01" => "ESTABLISHED",
        "02" => "SYN_SENT",
        "03" => "SYN_RECV",
        "04" => "FIN_WAIT1",
        "05" => "FIN_WAIT2",
        "06" => "TIME_WAIT",
        "07" => "CLOSE",
        "08" => "CLOSE_WAIT",
        "09" => "LAST_ACK",
        "0A" => "LISTEN",
        "0B" => "CLOSING"
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

      def connections(kind : Symbol = :all, pid : Int32 = 0, max : Int32 = 0, skip_uids : Bool = false)
        tmap = ConnectionsKinds.fetch(kind, nil)
        raise "Invalid connection kind #{kind}" unless tmap

        root = Common::HOST_PROC

        if !pid
          inodes = all_proc_inodes(root, max)
        else
          inodes = proc_inodes(root, pid, max)
          if inodes.size == 0
            return [] of ConnectionStat
          end
        end

        stats_from_inodes(root, pid, tmap, inodes, skip_uids)
      rescue err
        raise "Failed to get pid, #{pid}: #{err}"
      end

      def stats_from_inodes(
        root : String,
        pid : Int32 = 0,
        tmap : Array(NetConnectionKindType) = [] of NetConnectionKindType,
        inodes : Hash(String, Array(InodeMap)) = {} of String => Array(InodeMap),
        skip_uids : Bool = false
      )
        dups = [] of String
        tmap.reduce do |stats, t|
          path = pid ?
            File.join(root, pid.to_s, "net", t.filename) :
            File.join(root, "net", t.filename)

          case t.family
          when AF_INET, AF_INET6
            ls = process_inet(path, t, inodes, pid)
          when AF_UNIX
            ls = process_unix(path, t, inodes, pid)
          end

          ls.each do |c|
            # Build TCP key to id the connection uniquely
            # socket type, src ip, src port, dst ip, dst port and state should be enough
            # to prevent duplications.
            conn_key = "%d-%s:%d-%s:%d-%s" % [
              c.sock_type,
              c.laddr.ip,
              c.laddr.port,
              c.raddr.ip,
              c.raddr.port,
              c.status
            ]

            next if dups.includes?(conn_key)

            conn = ConnectionStat.new(
              fd: c.fd,
              family: c.family,
              type: c.type,
              laddr: c.laddr,
              raddr: c.raddr,
              status: c.status,
              pid: c.pid,
              uids: [] of Int32
            )

            if c.pid == 0
              conn = conn.copy_with(pid: c.bound_pid)
            else
              conn = conn.copy_with(pid: c.pid)
            end

            unless skip_uids
              # fetch process owner Real, effective, saved set, and filesystem UIDs
              proc = InternalProcess.new(pid: conn.pid)
              conn = conn.copy_with(uids: proc.uids)
            end

            stats << conn
            dups << conn_key
            stats
          end
        end
      end

      def proc_inodes(root : String, pid : Int32, max : Int32)
        dir_path = File.join(root, pid.to_s, "fd")
        dir = Dir.children(dir_path)

        dir.reduce({} of String => Array(InodeMap)) do |map, fd|
          inode_path = File.join(root, pid.to_s, "fd", fd)

          begin
            inode = File.readlink(inode_path)
          rescue e
            next map
          end

          if inode.starts_with?("socket:[")
            next map
          end

          # the process is using a socket
          l = inode.size
          inode = inode[8..(l - 1)]

          unless map[inode]?
            map[inode] = [] of InodeMap
          end

          fd = fd.to_u32
          i = InodeMap.new(
            pid: pid,
            fd: fd
          )

          map[inode] << i
          map
        end
      end

      def pids
        fnames = Dir.children(Common::HOST_PROC)
        fnames.reduce([] of Int32) do |pids, fname|
          pid = fname.to_i?
          next pids unless pid
          pids << pid
          pids
        end
      end

      def all_proc_inodes(root : String, max : Int32)
        self.pids.reduce({} of String => Array(InodeMap)) do |map, pid|
          begin
            t = proc_inodes(root, pid, max)
          rescue e
            next map
          end

          if t.size == 0
            next map
          end

          map = map.merge(t)
        end
      end

      # Decodes addresses represented in proc/net/*
      #
      # Example:
      # ```
      # "0500000A:0016" -> "10.0.0.5", 22
      # "0085002452100113070057A13F025401:0035" -> "85:24:5210:113:700:57a1:3f02:5401", 53
      # ```
      def decode_address(family : Number, src : String)
        t = src.split(":")
        raise "#{src} does not contain port" unless t.size == 2

        addr = t[0]
        port = t[1].to_u32(16)

        if family == AF_INET
          ip = Subnet::IPv4.parse_data(addr.hexbytes)
        else
          ip = Subnet::IPv6.parse_hex(addr)
        end

        Addr.new(ip.to_s, port)
      rescue
        return nil
      end

      def process_inet(
        file : String,
        kind : NetConnectionKindType,
        inodes : Hash(String, Array(InodeMap)),
        filter_pid : Int32
      )
        if file.ends_with?("6") && !File.exists?(file)
          # IPv6 is not supported, return nil
          return nil
        end

        # Read the contents of the /proc file with a single read sys call.
        # This minimizes duplicates in the returned connections
        # For more info:
        # https://github.com/shirou/gopsutil/pull/361
        contents = File.read(file)
        lines = contents.strip.split("\n")

        lines[1..].reduce([] of ConnTmp) do |ret, line|
          fields = line.split(/\s+/)
          if fields.size < 10
            next ret
          end
          laddr = fields[1]
          raddr = fields[2]
          status = fields[3]
          inode = fields[9]
          pid = 0
          fd = 0

          if i = inodes[inode]?
            pid = i[0].pid
            fd = i[0].fd
          end

          if filter_pid > 0 && filter_pid != pid
            next ret
          end

          if kind.sock_type == SOCK_STREAM
            status = TCP_STATUSES[status]
          else
            status = "NONE"
          end

          la = decode_address(kind.family, laddr)
          next ret unless la

          ra = decode_address(kind.family, raddr)
          next ret unless ra

          ret << ConnTmp.new(
            fd: fd.to_u32,
            family: kind.family,
            sock_type: kind.sock_type,
            laddr: la,
            raddr: ra,
            status: status,
            pid: pid
          )
        end
      end

      def process_unix(
        file : String,
        kind : NetConnectionKindType,
        inodes : Hash(String, Array(InodeMap)),
        filter_pid : Int32
      )
        # Read the contents of the /proc file with a single read sys call.
        # This minimizes duplicates in the returned connections
        # For more info:
        # https://github.com/shirou/gopsutil/pull/361
        contents = File.read(file)
        lines = contents.strip.split("\n")

        lines[1..].reduce([] of ConnTmp) do |ret, line|
          tokens = line.split(/\s+/)
          if tokens.size < 6
            next ret
          end

          st = tokens[4].to_i
          next ret unless st

          inode = tokens[6]

          pairs = inodes[inode]? || [] of InodeMap
          pairs.each do |pair|
            if filter_pid > 0 && filter_pid != pair.pid
              next ret
            end

            path = ""
            if tokens.size == 8
              path = tokens[tokens.size - 1]
            end

            ret << ConnTmp.new(
              fd: pair.fd,
              family: kind.family,
              sock_type: st.to_u32,
              laddr: Addr.new(ip: path, port: 0),
              pid: pair.pid,
              status: "NONE",
              path: path
            )
            ret
          end
        end
      end

      record NetConnectionKindType,
          family    : UInt32,
          sock_type : UInt32,
          filename  : String

      record InodeMap,
        pid : Int32,
        fd  : UInt32

      record ConnTmp,
        fd        : UInt32 = 0_u32,
        family    : UInt32 = 0_u32,
        sock_type : UInt32 = 0_u32,
        laddr     : Addr? = nil,
        raddr     : Addr? = nil,
        status    : String = "",
        pid       : Int32 = 0,
        bound_pid : Int32 = 0,
        path      : String = ""

      record InternalProcess, pid : Int32, uids : Array(Int32) do
        include JSON::Serializable

        # Get status from /proc/(pid)/status
        def fill_from_status
          stat_path = File.join(Common::HOST_PROC, pid.to_s, "status")
          lines = File.read_lines(stat_path)
          lines.each do |line|
            tab_parts = line.split("\t", 2)
            if tab_parts.size < 2
              next
            end
            value = tab_parts[1]
            if tabparts[0].rstrip(":") == "Uid"
              value.split("\t").each do |i|
                v = i.to_i
                uids << v
              end
            end
          end
        end
      end
    end
  end
end
