---
name: resolve-gcp-project
description: Use when you have a human-readable GCP project name or keywords (e.g. "marketing qa", "production analytics") and need the exact GCP Project ID that a gcloud/bq/gsutil command requires. Matches descriptive names against projectId, name, and labels (env, business-unit, cost-center) from `gcloud projects list`.
---

# resolve-gcp-project Skill

## Description
This skill resolves a human-readable Google Cloud Platform (GCP) project name or keywords into its official GCP Project ID. This is useful when tools require an exact Project ID but the user only provides a descriptive name (e.g., "marketing qa").

## Usage
Use this skill when you need to find the exact GCP Project ID corresponding to a descriptive project name.

**Example:**
"Resolve the project ID for 'marketing qa'"
"What is the GCP Project ID for 'production analytics'?"

## Implementation Details

The `resolve-gcp-project` skill will perform the following steps:

1.  **Input:** Accepts a string representing the descriptive project name or keywords.
2.  **Retrieve Projects:** Executes `gcloud projects list --format=json` to get a comprehensive list of all projects the current gcloud configuration has access to.
3.  **Parse and Match:** It parses the JSON output and iterates through each project's metadata (including `projectId`, `name`, and `labels` such as `env`, `environment`, `business-unit`, `cost-center`, `business-purpose`).
4.  **Identification:** It performs a robust search, looking for:
    *   Exact matches in `projectId` or `name`.
    *   Partial, case-insensitive matches in `projectId` or `name`.
    *   Keyword matches within `labels` (e.g., if "marketing" and "qa" are provided, it looks for projects with "marketing" in a business-related label and "qa" in an environment label).
5.  **Output Resolution:**
    *   If a single, highly confident match is found, the skill returns that `projectId`.
    *   If multiple plausible matches are found, the skill will list them (e.g., by `projectId` and `name` with relevant labels) and prompt the user to choose the correct one.
    *   If no matches are found, it will inform the user and suggest providing more specific keywords or the exact Project ID.

This skill should be integrated as a custom tool or a set of predefined bash/python functions within the agent's environment to allow other tools (like `search_bq_tables`) to call it.
