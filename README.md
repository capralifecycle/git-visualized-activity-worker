# git-visualized-activity-worker

This project builds a Docker image that we schedule to run as a
Fargate task. The container will clone all repos, generate `commits.csv`
and upload this to the distribution used for
https://github.com/capraconsulting/git-visualized-activity/
that is deployed at https://gva.capra.tv.

TODO: Link to CloudFormation setup.

## Testing locally using Docker and aws-vault

```bash
# Edit these
export CALS_GITHUB_TOKEN=personal-access-token-read-scope
export BUCKET_NAME=s3-bucket-to-upload-to
export CF_DISTRIBUTION=cloudfront-distribution-to-invalidate

# Build locally
docker build -t gva-test .

# Run locally. Edit aws-vault target profile.
aws-vault exec capra -- \
  docker run \
    -it --rm \
    -v "$PWD:/data" \
    -e AWS_REGION \
    -e AWS_ACCESS_KEY_ID \
    -e AWS_SECRET_ACCESS_KEY \
    -e AWS_SESSION_TOKEN \
    -e CALS_GITHUB_TOKEN \
    -e BUCKET_NAME \
    -e CF_DISTRIBUTION \
    -w /app \
    gva-test

# Inside the container
./main.sh
```

`main.sh` can also be used outside Docker, but you will need to have the
required dependencies set up. If `BUCKET_NAME` and `CF_DISTRIBUTION` is
not set, upload and invalidation will be skipped.
