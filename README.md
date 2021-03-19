# filetranspiler
Creates an [Ignition](https://github.com/coreos/ignition) JSON file from a fake root.

See also [fcct](https://github.com/coreos/fcct).

## Getting filetranspiler

It's recommended to use a released version of filetranspiler. See [releases](https://github.com/ashcrow/filetranspiler/releases) page for the latest releases.

## Building

### Container Image
Requires `podman`
```
$ make container
```

## Running

### Source

These items are required when running outside of the container.

- Python 3 (3.6+ recommended)
- [PyYAML](https://github.com/yaml/pyyaml)
- python3-magic
- file-magic

```
./filetranspile -i ignition.json -f fakeroot
```

### Container Image
**Note**: When using the container don't forget to mount the host directory that houses your ignition
file and fake root in to the container!
```
$ podman run --rm -ti --volume `pwd`:/srv:z localhost/filetranspiler:latest -i ignition.json -f fakeroot
```

## Example
```
$ tree fakeroot
fakeroot/
└── etc
    ├── hostname
    ├── hostname.link -> hostname
    ├── resolve.conf
    └── sysconfig
        └── network-scripts
            ├── ifcfg-blah
            └── ifcfg-fake

3 directories, 5 files
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
      "path": "/var/foo/bar",
      "filesystem": "root",
      "mode": 420,
      "contents": { "source": "data:,example%20file%0A" }
    }]
  }
}

$ ./filetranspile -i test/ignition.json -f test/fakeroot -p
{
    "ignition": {
        "version": "2.3.0"
    },
    "storage": {
        "files": [
            {
                "contents": {
                    "source": "data:,example%20file%0A"
                },
                "filesystem": "root",
                "mode": 420,
                "path": "/var/foo/bar"
            },
            {
                "contents": {
                    "source": "data:text/plain;charset=us-ascii;base64,c29tZXRoaW5nCg=="
                },
                "filesystem": "root",
                "mode": 436,
                "path": "/etc/hostname"
            },
            {
                "contents": {
                    "source": "data:text/plain;charset=us-ascii;base64,c2VhcmNoIDEyNy4wLjAuMQpuYW1lc2VydmVyIDEyNy4wLjAuMQo="
                },
                "filesystem": "root",
                "mode": 436,
                "path": "/etc/resolve.conf"
            },
            {
                "contents": {
                    "source": "data:text/plain;charset=us-ascii;base64,YmxhaCBibGFoIGJsYWgKMTIzNDU2Nzg5MApibGFoIGJsYWggYmxhaAo="
                },
                "filesystem": "root",
                "mode": 436,
                "path": "/etc/sysconfig/network-scripts/ifcfg-blah"
            },
            {
                "contents": {
                    "source": "data:text/plain;charset=us-ascii;base64,ZmFrZQo="
                },
                "filesystem": "root",
                "mode": 436,
                "path": "/etc/sysconfig/network-scripts/ifcfg-fake"
            }
        ],
        "links": [
            {
                "filesystem": "root",
                "hard": false,
                "path": "/etc/hostname.link",
                "target": "hostname"
            }
        ]
    }
}
```
