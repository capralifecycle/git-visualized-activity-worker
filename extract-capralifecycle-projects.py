#!/usr/bin/env python3
import yaml
import sys
import os.path


def get_capralifecycle_config(cals_tools_dir):
    with open(os.path.join(cals_tools_dir, "github/capralifecycle.yml"), "r") as f:
        return yaml.load(f)


def build_list(cals_tools_dir):
    result = []
    for project in get_capralifecycle_config(cals_tools_dir)["projects"]:
        for repo in project["github"]["capralifecycle"]["repos"]:
            result.append({"name": repo["name"], "project": project["name"]})
    return result


if __name__ == "__main__":
    cals_tools_dir = sys.argv[1]

    for item in build_list(cals_tools_dir):
        print("%s,%s" % (item["name"], item["project"]))
