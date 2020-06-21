# git-visualized-activity-worker

[![Build Status](https://jenkins.capra.tv/buildStatus/icon?job=cals-internal/git-visualized-activity-worker/master)](https://jenkins.capra.tv/job/cals-internal/job/git-visualized-activity-worker/job/master/)

This project builds a Docker image that we schedule to run as a
Fargate task. The container will clone all repos, generate `commits.csv`
and upload this to the distribution used for
https://github.com/capraconsulting/git-visualized-activity/
that is deployed at https://gva.capra.tv.

The internal CloudFormation setup is stored at
https://github.com/capralifecycle/aws-infrastructure/tree/master/cloudformation/git-visualized-activity

## Testing locally using Docker and aws-vault

```bash
# Fetch configuration from this namespace.
export PARAMS_PREFIX=/incub-gva-worker

# To override configuration, these can be set.
export CALS_GITHUB_TOKEN=personal-access-token-read-scope
export BUCKET_NAME=s3-bucket-to-upload-to
export CF_DISTRIBUTION=cloudfront-distribution-to-invalidate

# Build locally
docker build -t gva-test .

# Run locally. Edit aws-vault target profile.
aws-vault exec liflig-incubator-admin -- \
  docker run \
    -it --rm \
    -v "$PWD:/data" \
    -v "$PWD/main.sh:/app/main.sh" \
    -v "$PWD/lib.sh:/app/lib.sh" \
    -e AWS_DEFAULT_REGION \
    -e AWS_ACCESS_KEY_ID \
    -e AWS_SECRET_ACCESS_KEY \
    -e AWS_SESSION_TOKEN \
    -e PARAMS_PREFIX \
    -e CALS_GITHUB_TOKEN \
    -e BUCKET_NAME \
    -e CF_DISTRIBUTION \
    gva-test
```

`main.sh` can also be used outside Docker, but you will need to have the
required dependencies set up. If `BUCKET_NAME` and `CF_DISTRIBUTION` is
not set, upload and invalidation will be skipped.
