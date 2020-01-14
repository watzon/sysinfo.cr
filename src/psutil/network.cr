require "json"
require "./network/*"

module SysInfo
  class Network
    record IOCounterStat,
           name : String,
           bytes_sent : UInt64,
           bytes_recv : UInt64,
           packets_sent : UInt64,
           packets_recv : UInt64,
           errin : UInt64,
           errout : UInt64,
           dropin : UInt64,
           dropout : UInt64,
           fifoin : UInt64,
           fifoout : UInt64 do
      include JSON::Serializable
    end

    # Addr is implemented compatibility to psutil
    record Addr,
           ip : String,
           port : UInt32 do
      include JSON::Serializable
    end

    record ConnectionStat,
           fd : UInt32,
           family : UInt32,
           type : UInt32,
           laddr : Addr,
           raddr : Addr,
           status : String,
           uids : Array(Int32),
           pid : Int32 do
      include JSON::Serializable
    end

    # System wide stats about different network protocols
    record ProtocolCountersStat,
           protocol : String,
           stats : Hash(String, Int64) do
      include JSON::Serializable
    end

    # NetInterfaceAddr is designed for represent interface addresses
    record InterfaceAddr,
           addr : String do
      include JSON::Serializable
    end

    record InterfaceStat,
           index : Int32,
           mtu : Int32,
           name : String,
           hardware_addr : String,
           flags : Array(String),
           addrs : Array(InterfaceAddr) do
      include JSON::Serializable
    end

    record FilterStat,
           conn_track_count : Int64,
           conn_track_max : Int64 do
      include JSON::Serializable
    end

    # ConntrackStat has conntrack summary info
    record ConntrackStat,
           entries : UInt32,
           searched : UInt32,
           found : UInt32,
           new : UInt32,
           invalid : UInt32,
           ignore : UInt32,
           delete : UInt32,
           delete_list : UInt32,
           insert : UInt32,
           insert_failed : UInt32,
           drop : UInt32,
           early_drop : UInt32,
           icmp_error : UInt32,
           expect_new : UInt32,
           expect_create : UInt32,
           expect_delete : UInt32,
           search_restart : UInt32
    include JSON::Serializable
  end

    record ConnectionStatList, items : Array(ConntrackStat) do
      # Add an item to the list
      def append(c : ConntrackStat)
        items.push(c)
      end

      # Summary returns a single-element list with totals from all list items.
      def summary
        {% for var in ConntrackStat.class_vars %}
          {{var.id}} = 0.0
        {% end %}

        items.each do |cs|
          {% for var in ConntrackStat.class_vars %}
            {{var.id}} += cs.{{var.id}}
          {% end %}
        end

        ConntrackStat.new(
          {% for var in ConntrackStat.class_vars %}
            {{var.id}}: {{var.id}},
          {% end %}
        )
      end
    end

    ConstMap = {
      "unix"  => 0x1,
      "TCP"   => 0x1,
      "UDP"   => 0x2,
      "IPv4"  => 0x2,
      "IPv6"  => 0xa
    }

    def interfaces
      
    end

    def get_io_counters(n : Array(IOCounterStat))

    end

    private def parse_net_line(line : String)
      
    end

    private def parse_net_address(line : String)

    end
  end
end
