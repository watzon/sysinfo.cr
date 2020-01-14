require "./psutil/*"

module SysInfo
end

mem = SysInfo::Memory.new
pp mem.swap_memory
