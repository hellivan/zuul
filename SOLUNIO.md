# Solunio fork

Upstream Zuul (https://opendev.org/zuul/zuul) plus the patches we need
before they are released. The branch is the upstream release tag with our
commits on top, e.g. `14.3.0-github-forced-push` = tag `14.3.0` + fix.

Patches:

- GitHub: reconfigure after a force push if the config changed (first
  commit of the branch; the part we send upstream, without this file and
  the build script).

## Building the images

Needs podman, network access and about 6 GB of free disk space (set
`TMPDIR` if `/var/tmp` is small).

```
git switch 14.3.0-github-forced-push     # all changes committed
tools/build-solunio-images.sh            # build
PUSH=1 tools/build-solunio-images.sh     # build and push
```

The script builds the `zuul-scheduler`, `zuul-merger` and `zuul-executor`
targets of the upstream `Dockerfile` from a clean export of `HEAD` and tags
them `<REGISTRY>/zuul-<component>:<version>-<sha>`.

Set `COMPONENTS` to build fewer images, `REGISTRY` to change the target.

Check an image: `podman run --rm --entrypoint python3 <image> -c "import zuul.merger.merger as m, inspect; print('diff_only' in inspect.signature(m.Repo.getFilesChanges).parameters)"`
should print `True`.

Which components need the patch: the scheduler (asks the merger), the merger
and the executor (both answer the request). `zuul-web` and the launcher run
the upstream images.

## Moving to a new Zuul version

1. `git fetch origin --tags`
2. `git switch -c <version>-github-forced-push <version>`
3. Cherry-pick the fix and this file's commit from the previous branch.
4. Run the tests (`tests/unit/test_github_driver.py`, see `tools/test-setup-docker.sh`
   for ZooKeeper and MariaDB) and build the images.
5. Update the three `image` values in cluster-apps `apps/zuul/application.yaml`.

Once a Zuul release contains the fix, drop the `image` values and use the
upstream images again.
