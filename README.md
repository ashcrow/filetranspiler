# filetranspiler
Creates an update `Ignition` json file with additions from a fake root.

## Building

### Container Image
```
$ podman build . -t filetranspiler:latest
```

## Running

### Source
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
usage: filetranspile [-h] -i IGNITION -f FAKE_ROOT [-o OUTPUT]

optional arguments:
  -h, --help            show this help message and exit
  -i IGNITION, --ignition IGNITION
                        Path to ignition file to use as the base
  -f FAKE_ROOT, --fake-root FAKE_ROOT
                        Path to the fake root
  -o OUTPUT, --output OUTPUT
                        Where to output the file. If empty, will print to
                        stdout.
$ cat ignition.json 
{
  "ignition": { "version": "3.0.0" },
  "storage": {
    "files": [{
      "path": "/foo/bar",
      "mode": 420,
      "contents": { "source": "data:,example%20file%0A" }
    },
    {
        "path": "/etc/sysconfig/network-scripts/iftest",
        "mode": 420,
        "contents": { "source": "data:,example%20file%0A" }
    }]
  }
$ ./filetranspile -i ignition.json -f fake-root
{
    "ignition": {
        "version": "3.0.0"
    },
    "storage": {
        "files": [
            {
                "contents": {
                    "source": "data:,example%20file%0A"
                },
                "mode": 420,
                "path": "/foo/bar"
            },
            {
                "contents": {
                    "source": "data:,example%20file%0A"
                },
                "mode": 420,
                "path": "/etc/sysconfig/network-scripts/iftest"
            },
            {
                "contents": {
                    "source": "data:,something%0A"
                },
                "mode": 384,
                "path": "/etc/hostname"
            },
            {
                "contents": {
                    "source": "data:,search%20127.0.0.1%0Anameserver%20127.0.0.1%0A"
                },
                "mode": 436,
                "path": "/etc/resolve.conf"
            },
            {
                "contents": {
                    "source": "data:,fake%0A"
                },
                "mode": 436,
                "path": "/etc/sysconfig/network-scripts/ifcfg-fake"
            },
            {
                "contents": {
                    "source": "data:,blah%20blah%20blah%0A1234567890%0Ablah%20blah%20blah%0A"
                },
                "mode": 436,
                "path": "/etc/sysconfig/network-scripts/ifcfg-blah"
            }
        ]
    }
}
```
