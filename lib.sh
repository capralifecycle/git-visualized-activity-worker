#!/bin/bash
set -eu

install_cals_cli() {
  npm install -g @capraconsulting/cals-cli
}

fetch_gva() {
  rm "$root/git-visualized-activity" -rf || :
  git clone --depth 1 https://github.com/capraconsulting/git-visualized-activity.git "$root/git-visualized-activity"
}

fetch_cals_tools() {
  rm "$root/cals-tools" -rf || :
  git clone --depth 1 https://github.com/capralifecycle/cals-tools.git "$root/cals-tools"
}

fetch_resources_definition() {
  rm "$root/resources-definition" -rf || :
  git clone --depth 1 https://github.com/capralifecycle/resources-definition.git "$root/resources-definition"
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
  repo_col=$3
  project_col=$4
  org=$5

  project_name=$(echo "$project_map" | awk -v reponame="$reponame" "{ if ($repo_col == reponame) { print $project_col } }")
  if [ "$project_name" == "" ]; then
    project_name="unknown-$org"
  fi

  echo "$project_name"
}

get_repos_def() {
  org=$1
  repos=$2

  if [ "$org" == "capralifecycle" ]; then
    project_map=$(set -e; ./extract-projects.py capralifecycle "$root/resources-definition")
    project_column=2
    repo_column=1
  elif [ "$org" == "capraconsulting" ]; then
    project_map=$(set -e; ./extract-projects.py capraconsulting "$root/resources-definition")
    project_column=2
    repo_column=1
  elif [ "$org" == "Cantara" ]; then
    project_map=$(cat "$root/cals-tools/github/stats/project-map-Cantara.csv")
    project_column=1
    repo_column=2
  else
    echo "Unknown org: $org"
    exit 1
  fi

  while read -r reponame; do
    project_name=$(set -e; get_project_name "$project_map" "$reponame" $repo_column $project_column "$org")
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
  (cd "$root/resources-definition" && git config --global mailmap.file "$PWD/git-mailmap.txt")
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
