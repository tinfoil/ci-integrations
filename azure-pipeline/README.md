## Step 1: API Information
At the top of `run_scan.sh`, there are some parameters that need to be filled in. Alternatively, you may configure these via environment variables.
* TOKEN 
* ACCESS_KEY
* API_ID
* SEVERITY_THRESHOLD (optional)
* POLL_WINDOW (optional)

To get a token and access key, go to My API Keys (top right, under your name) and add an API key.

To get your API ID, go to your API page, and grab the API ID from the URL:

`https://api-scanner.tinfoilsecurity.com/organizations/<organization_id>/apis/<api_id>/`

Optionally you may set the severity threshold, which is set to `High` by default. Issues found by the scan are classified according to their severity. Currently, severities take on one of the following values:

<p align=center>Info < Low < Medium < High</p>

Once the scan completes successfully, the script examines the issues found. If any cross the severity threshold, the script exits with status code 1.

You can also optionally set the poll window. When a scan successfully starts, the script will check the status of the scan every `POLL_WINDOW` seconds. 

## Step 2: Set up an API scan job
The file `azure-pipelines.yml` contains the configuration for a sample Azure Pipeline. It can be used as is, or just the api scan job portion can be copied and integrated into an existing pipeline. If you decide to pass in the parameters as environment variables, be sure to fill in the `env` field of the task.