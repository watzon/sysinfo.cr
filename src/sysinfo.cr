require "./sysinfo/*"

module SysInfo
end

net = SysInfo::Network.new
pp net.connections
