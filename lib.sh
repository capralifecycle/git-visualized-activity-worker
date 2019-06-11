#!/bin/bash
set -eu

install_cals_cli() {
  rm "$root/cals-cli" -rf || :
  git clone --depth 1 https://github.com/capralifecycle/cals-cli.git "$root/cals-cli"
  (cd "$root/cals-cli" && npm install && npm link)
}

fetch_gva() {
  rm "$root/git-visualized-activity" -rf || :
  git clone --depth 1 https://github.com/capraconsulting/git-visualized-activity.git "$root/git-visualized-activity"
}

fetch_cals_tools() {
  rm "$root/cals-tools" -rf || :
  git clone --depth 1 https://github.com/capralifecycle/cals-tools.git "$root/cals-tools"
}

refresh_git_repos() {
  org=$1
  repos=$2

  # Mark candidates for post-removal.
  while IFS= read -r -d '' line; do
    touch "$line/.delete-candidate"
  done < <(find "$root/repos/$org/" -mindepth 1 -maxdepth 1 -type d -print0)

  while read -r reponame; do
    # Allow to run with cache
    if [ -d "$root/repos/$org/$reponame" ]; then
      rm "$root/repos/$org/$reponame/.delete-candidate"
      (cd "$root/repos/$org/$reponame" && git fetch)
    else
      git clone --bare --single-branch https://github.com/$org/$reponame.git "$root/repos/$org/$reponame"
    fi
  done <<< "$repos"

  # Delete stale directories from previous runs
  while IFS= read -r -d '' line; do
    # Just some safeguards..
    p=$(set -e; realpath "$line")
    if [ "$p" != "/" ]; then
      rm -rf "$p"
    fi
  done < <(find "$root/repos/$org" -mindepth 2 -maxdepth 2 -name .delete-candidate -print0)
}

get_project_name() {
  project_map=$1
  reponame=$2
  project_col=$3

  project_name=$(echo "$project_map" | grep "^$reponame," | cut -d, -f$project_col)
  if [ "$project_name" == "" ]; then
    project_name="unknown"
  fi

  echo "$project_name"
}

get_repos_def() {
  org=$1
  repos=$2

  if [ "$org" == "capralifecycle" ]; then
    project_map=$(set -e; ./extract-capralifecycle-projects.py "$root/cals-tools")
    project_column=2
  elif [ "$org" == "capraconsulting" ]; then
    project_map=$(cat "$root/cals-tools/github/stats/repo-list-capraconsulting.csv")
    project_column=3
  elif [ "$org" == "Cantara" ]; then
    project_map=$(cat "$root/cals-tools/github/stats/repo-list-Cantara.csv")
    project_column=3
  else
    echo "Unknown org: $org"
    exit 1
  fi

  while read -r reponame; do
    project_name=$(set -e; get_project_name "$project_map" "$reponame" $project_column)
    branch=$(cd "$root/repos/$org/$reponame" && git rev-parse --abbrev-ref HEAD)

    echo "$reponame,$branch,$project_name"
  done <<< "$repos"
}

get_repo_list() {
  excluded_file="$root/cals-tools/github/stats/excluded.txt"
  org=$1

  repos=$(set -e; cals github list-repos --include-abandoned --csv --org $org | tail -n +2 | cut -d, -f1)
  while read -r reponame; do
    if grep -qF "$org/$reponame" "$excluded_file"; then
      continue
    fi

    echo "$reponame"
  done <<< "$repos"
}

process_repos() {
  "$root/git-visualized-activity/generate-commits.sh" clean

  for org in capralifecycle capraconsulting Cantara; do
    mkdir -p "$root/repos/$org"
    repos=$(set -e; get_repo_list $org)

    refresh_git_repos $org "$repos"

    repo_def=$(set -e; get_repos_def "$org" "$repos")
    if [ "$repo_def" != "" ]; then
      SKIP_REFRESH_STALE=y "$root/git-visualized-activity/generate-commits.sh" add-group <(echo "$repo_def") $org "$root/repos/$org"
    fi
  done
}

setup_mailmap() {
  (cd "$root/cals-tools/github/stats" && git config --global mailmap.file "$PWD/mailmap.txt")
}

upload_commits() {
  if [ -z "${BUCKET_NAME:-}" ]; then
    echo "BUCKET_NAME not set - skipping upload"
  else
    aws s3 cp "$root/commits.csv" s3://$BUCKET_NAME/data/commits.csv
  fi
}

invalidate_distribution() {
  if [ -z "${CF_DISTRIBUTION:-}" ]; then
    echo "CF_DISTRIBUTION not set - skipping invalidation"
  else
    aws cloudfront create-invalidation --distribution-id "$CF_DISTRIBUTION" --paths /data/commits.csv
  fi
}
