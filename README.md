# Databricks Dockerfiles for data analysis

## Bayesian R image validation

`.github/workflows/bayesian-image.yml` runs for pull requests and pushes to
`main` that change `ubuntu/R/bayesian/` or the workflow. It can also be run
manually from the Actions tab. It requires no secrets or Databricks workspace
and does not publish an image.

BuildKit caches intermediate layers in GitHub Actions to avoid recompiling
unchanged R packages and CmdStan on every run.

The job lints the workflow and Dockerfile, runs Docker build checks, and builds
the actual pinned `linux/amd64` image. Offline container smoke tests check the
inherited `/databricks/python3` environment, load every explicitly installed R
package, exercise spatial libraries, and compile and sample a small Stan model
as a non-root user. A build failure includes unavailable base digests, R version
pins, package snapshots, or package dependencies. Installation warnings that
leave a package missing are caught by the smoke tests.

CmdStan is built with threading enabled during image construction, so users
can compile threaded models without rebuilding artifacts in the shared
root-owned installation.

To reproduce the build and R smoke checks locally:

```sh
docker build --pull --platform linux/amd64 -t bayesian-r:ci ubuntu/R/bayesian
docker run --rm --network none --user 10001:10001 --env HOME=/tmp --workdir /tmp \
  --mount "type=bind,source=$PWD/ubuntu/R/bayesian/tests,target=/tests,readonly" \
  --entrypoint Rscript bayesian-r:ci /tests/smoke.R
```

These checks validate the standalone container. Cluster startup, Spark/Rserve
integration, notebook behavior, and the selected Databricks Runtime and compute
access mode still require a workspace test. The `standard` image name does not
select the compute access mode.
