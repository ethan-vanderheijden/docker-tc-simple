# Docker Traffic Control

This is a fork of [lukaszlach/docker-tc](https://github.com/lukaszlach/docker-tc). There are two changes:
1. Removed the HTTP API.
2. Added support for specifying ingress and egress bandwidth limits separately.

**Docker Traffic Control** allows to set a rate limit on the container network and can emulate network conditions like delay, packet loss, duplication, and corrupt for the Docker containers, all that basing only on labels. **Project is written entirely in Bash** and is distributed as a [Docker image](https://hub.docker.com/r/lukaszlach/docker-tc/).

## Running

First run Docker Traffic Control daemon in Docker. It is best to run the container as `privileged` as it needs to enter other containers' network namespaces to set an egress bandwidth limit (if you aren't using this feature, the `NET_ADMIN` capability is enough). Additionally, it requires the host machine's `/var/run/docker.sock` to observe Docker events and query container details.

```bash
docker run -d \
    --name docker-tc \
    --network host \
    --pid host \
    --privileged \
    --restart always \
    -v /var/run/docker.sock:/var/run/docker.sock \
    ethanvdh/docker-tc
```

This repository contains `docker-compose.yml` file in root directory. You can use it instead of manually running `docker run` command. Newest version of image will be pulled automatically and the container will run in daemon mode.

```bash
git clone https://github.com/ethanvdh/docker-tc-simple.git
cd docker-tc-simple
docker-compose up -d
```

## Usage

After the daemon is up it scans all running containers and starts listening for `container:start` events triggered by Docker Engine. When a new container is up (also a new Swarm service) and contains `com.docker-tc.enabled` label set to `1`, Docker Traffic Control starts applying network traffic rules according to the rest of the labels from `com.docker-tc` namespace it finds.

Docker Traffic Control recognizes the following labels:

* `com.docker-tc.enabled` - when set to `1` the container network rules will be set automatically, any other value or if the label is not specified - the container will be ignored
*  `com.docker-tc.limit_ingress` - bandwidth or rate limit for traffic entering the container, accepts a floating point number, followed by a unit, or a percentage value of the device's speed (e.g. 70.5%). Following units are recognized:
    * `bit`, `kbit`, `mbit`, `gbit`, `tbit`
    * `bps`, `kbps`, `mbps`, `gbps`, `tbps`
    * to specify in IEC units, replace the SI prefix (k-, m-, g-, t-) with IEC prefix (ki-, mi-, gi- and ti-) respectively
* `com.docker-tc.limit_egress` - same as `limit_ingress` but for traffic leaving the container
* `com.docker-tc.delay` - length of time packets will be delayed, accepts a floating point number followed by an optional unit:
    * `s`, `sec`, `secs`
    * `ms`, `msec`, `msecs`
    * `us`, `usec`, `usecs` or a bare number
* `com.docker-tc.loss` - percentage loss probability to the packets outgoing from the chosen network interface
* `com.docker-tc.duplicate` - percentage value of network packets to be duplicated before queueing
* `com.docker-tc.corrupt` - emulation of random noise introducing an error in a random position for a chosen percent of packets

> Read the [tc command manual](http://man7.org/linux/man-pages/man8/tc.8.html) to get detailed information about parameter types and possible values.

Run the `busybox` container on custom network to create virtual network interface, specify all possible labels and try to `ping google.com` domain.

```bash
docker network create test-net
docker run -it \
	--net test-net \
	--label "com.docker-tc.enabled=1" \
	--label "com.docker-tc.limit=1mbps" \
	--label "com.docker-tc.delay=100ms" \
	--label "com.docker-tc.loss=50%" \
	--label "com.docker-tc.duplicate=50%" \
	--label "com.docker-tc.corrupt=10%" \
	busybox \
	ping google.com
```

You should see output similar to shown below, `ping` correctly reports duplicates, packets are delayed and some of them lost.

```
PING google.com (216.58.215.78): 56 data bytes
64 bytes from 216.58.215.78: seq=0 ttl=54 time=1.010 ms
64 bytes from 216.58.215.78: seq=1 ttl=54 time=101.031 ms
64 bytes from 216.58.215.78: seq=2 ttl=54 time=101.045 ms
64 bytes from 216.58.215.78: seq=3 ttl=54 time=101.011 ms
64 bytes from 216.58.215.78: seq=4 ttl=54 time=101.028 ms
64 bytes from 216.58.215.78: seq=5 ttl=54 time=101.060 ms
64 bytes from 216.58.215.78: seq=5 ttl=54 time=154.685 ms (DUP!)
64 bytes from 216.58.215.78: seq=6 ttl=54 time=101.084 ms
64 bytes from 216.58.215.78: seq=8 ttl=54 time=101.085 ms
64 bytes from 216.58.215.78: seq=8 ttl=54 time=1001.130 ms (DUP!)
64 bytes from 216.58.215.78: seq=11 ttl=54 time=102.218 ms
64 bytes from 216.58.215.78: seq=15 ttl=54 time=114.437 ms
64 bytes from 216.58.215.78: seq=16 ttl=54 time=101.471 ms
64 bytes from 216.58.215.78: seq=17 ttl=54 time=101.068 ms
64 bytes from 216.58.215.78: seq=17 ttl=54 time=1001.162 ms (DUP!)
64 bytes from 216.58.215.78: seq=19 ttl=54 time=101.104 ms
^C
--- google.com ping statistics ---
20 packets transmitted, 13 packets received, 3 duplicates, 35% packet loss
round-trip min/avg/max = 1.010/152.299/1001.162 ms
```

## Supported platforms

Docker Traffic Control only works on Linux distributions like Debian, Ubuntu, CentOS or Fedora.

* MacOS - not supported due to lack of host network mode support
* Windows - not supported due to separate network stack between Linux and Windows containers

## Licence

MIT License

Copyright (c) 2018-2019 Łukasz Lach <llach@llach.pl>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
