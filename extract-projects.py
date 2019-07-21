#!/usr/bin/env python3
import os.path
import sys

import yaml


def get_resources(resources_dir):
    with open(os.path.join(resources_dir, "resources.yaml"), "r") as f:
        return yaml.safe_load(f)


def build_list(resources_dir, github_organization):
    result = []
    for project in get_resources(resources_dir)["projects"]:
        for org in project["github"]:
            if org["organization"] == github_organization:
                for repo in org["repos"]:
                    result.append({"name": repo["name"], "project": project["name"]})
    return result


if __name__ == "__main__":
    github_organization = sys.argv[1]
    resources_dir = sys.argv[2]

    for item in build_list(resources_dir, github_organization):
        print("%s,%s" % (item["name"], item["project"]))
