# SysInfo.cr

This shard is a port of [shirou/gopsutil](https://github.com/shirou/gopsutil/) and [giampaolo/psutil](https://github.com/giampaolo/psutil/), but for Crystal. It is set up to be completely cross platform (although right now only Linux is supported). It's main purpose is for system monitoring, profiling, limiting process resources, and management of running processes. It implements many functionalities offered by classic UNIX command line tools, such as _ps_, _top_, _iotop_, _lsof_, _netstat_, _ifconfig_, _free_, and many others.

## Supported Platforms

- [x] Linux
- [ ] macOS
- [ ] Windows
- [ ] FreeBSD, OpenBSD, NetBSD
- [ ] Sun Solaris
- [ ] AIX

...both *32-bit* and *64-bit* architectures.

## Contributing

1. [Fork it](https://github.com/watzon/sysinfo.cr/fork)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new [Pull Request](https://github.com/watzon/sysinfo.cr/pulls)

## Contributors

- [watzon](https://github.com/watzon/sysinfo.cr) Chris Watson - creator, maintainer
