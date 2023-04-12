# emulate-OpenBSD

GitHub Actions for OpenBSD.

```yaml
runs-on: macos-12
steps:
- name: Bootstrap OpenBSD
  uses: moritzbuhl/emulate-OpenBSD@v1
  with:
    operating-system: openbsd-latest
- name: Build
  run: |
    cd /home
    git clone https://github.com/foo/bar.git
    cd bar && make
```

### Supported operating systems

| Supported OS  | Input |
| ------------- | ----- |
| OpenBSD 7.3 -current | `openbsd-current` |
| OpenBSD 7.3 -stable | `openbsd-7.3`, `openbsd-stable` |
| OpenBSD 7.2 -stable | `openbsd-7.2` |

### Limitations
- :heavy_exclamation_mark: This Action is still very experimental :heavy_exclamation_mark:
- Only `run.shell=bash` steps are propogated to the guest at the moment. `run.shell=python` will run in the host.
- No support for Actions; just `run` steps.
