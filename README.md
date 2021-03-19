# filetranspiler
Creates an [Ignition](https://github.com/coreos/ignition) JSON file from a fake root.

See also [fcct](https://github.com/coreos/fcct).

## Getting filetranspiler

It's recommended to use a released version of filetranspiler. See [releases](https://github.com/ashcrow/filetranspiler/releases) page for the latest releases.

## Building

### Container Image
```
$ podman build . -t filetranspiler:latest
```

## Running

### Source

These items are required when running outside of the container.

- Python 3 (3.6+ recommended)
- [PyYAML](https://github.com/yaml/pyyaml)
- python3-magic
- file-magic

```
./filetranspile -i ignition.json -f fake-root
```

### Container Image
**Note**: When using the container don't forget to mount the host directory that houses your ignition
file and fake root in to the container!
```
$ podman run --rm -ti --volume `pwd`:/srv:z localhost/filetranspiler:latest -i ignition.json -f fake-root
```

## Example
```
$ tree fake-root
fake-root
└── etc
    ├── hostname
    ├── resolve.conf
    └── sysconfig
        └── network-scripts
            ├── ifcfg-blah
            └── ifcfg-fake

3 directories, 4 files
$ ./filetranspile --help
usage: filetranspile [-h] [-i IGNITION] -f FAKE_ROOT [-o OUTPUT] [-p]
                     [--dereference-symlinks] [--format {json,yaml}]
                     [--version]

optional arguments:
  -h, --help            show this help message and exit
  -i IGNITION, --ignition IGNITION
                        Path to ignition file to use as the base
  -f FAKE_ROOT, --fake-root FAKE_ROOT
                        Path to the fake root
  -o OUTPUT, --output OUTPUT
                        Where to output the file. If empty, will print to
                        stdout
  -p, --pretty          Make the output pretty
  --dereference-symlinks
                        Write out file contents instead of making symlinks
                        NOTE: Target files must exist in the fakeroot
  --format {json,yaml}  What format of file to write out. `yaml` or `json`
                        (default)
  --version             show program's version number and exit
$ cat ignition.json 
{
  "ignition": { "version": "2.3.0" },
  "storage": {
    "files": [{
      "path": "/foo/bar",
      "filesystem": "root",
      "mode": 420,
      "contents": { "source": "data:,example%20file%0A" }
    },
    {
        "path": "/etc/sysconfig/network-scripts/iftest",
        "filesystem": "root",
        "mode": 420,
        "contents": { "source": "data:,example%20file%0A" }
    }]
  }
}
$ ./filetranspile -i ignition.json -f fake-root
{"ignition": {"version": "2.3.0"}, "storage": {"files": [{"path": "/foo/bar", "filesystem": "root", "mode": 420, "contents": {"source": "data:,example%20file%0A"}}, {"path": "/etc/hostname", "filesystem": "root", "mode": 384, "contents": {"source": "data:text/plain;charset=us-ascii;base64,c29tZXRoaW5nCg=="}}, {"path": "/etc/resolve.conf", "filesystem": "root", "mode": 436, "contents": {"source": "data:text/plain;charset=us-ascii;base64,c2VhcmNoIDEyNy4wLjAuMQpuYW1lc2VydmVyIDEyNy4wLjAuMQo="}}, {"path": "/etc/sysconfig/network-scripts/ifcfg-fake", "filesystem": "root", "mode": 436, "contents": {"source": "data:text/plain;charset=us-ascii;base64,ZmFrZQo="}}, {"path": "/etc/sysconfig/network-scripts/ifcfg-blah", "filesystem": "root", "mode": 436, "contents": {"source": "data:text/plain;charset=us-ascii;base64,YmxhaCBibGFoIGJsYWgKMTIzNDU2Nzg5MApibGFoIGJsYWggYmxhaAo="}}], "links": [{"path": "/etc/hostname.link", "filesystem": "root", "target": "hostname", "hard": false}]}}
```
