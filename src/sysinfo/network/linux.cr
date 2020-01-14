module SysInfo
  class Network
    module Linux
      enum ConntrackCol
        CtEntries
	CtSearched
	CtFound
	CtNew
	CtInvalid
	CtIgnore
	CtDelete
	CtDeleteList
	CtInsert
	CtInsertFailed
	CtDrop
	CtEarlyDrop
	CtIcmpError
	CtExpectNew
	CtExpectCreate
	CtExpectDelete
	CtSearchRestart
      end

      # NetIOCounters returnes network I/O statistics for every network
      # interface installed on the system.  If pernic argument is false,
      # return only sum of all information (which name is 'all'). If true,
      # every network interface installed on the system is returned
      # separately.
      def io_counters(per_nic = true)

      end
    end
  end
end
