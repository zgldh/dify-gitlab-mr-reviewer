# Dify GitLab MR Reviewer

Dify GitLab MR Reviewer is a tool designed to automate the code review process for GitLab Merge Requests (MRs). It integrates with the Dify workflow to provide intelligent code review suggestions, helping developers identify potential issues and improve code quality.

## Features

- **Automated Code Review**: Automatically reviews GitLab MRs and provides feedback.
- **Integration with Dify**: Utilizes the Dify workflow for advanced code analysis.
- **Docker Trigger Support**: Easy deployment using Docker containers to trigger the workflow.
- **Logging and Monitoring**: Detailed logging and monitoring to ensure robust operation.

## Prerequisites

Before you begin, ensure you have the following installed:

- [GitLab](https://about.gitlab.com/) This reviewer can be applied to free GitLab instance. You need a personal access token to an account with access (Role `developer` at least) to the repository.
- [Dify](https://github.com/langgenius/dify) The AI workflow platform. You have to get the workflow URL and access token.
- [Docker](https://www.docker.com/) To proxy the GitLab system hook requests to Dify

## Installation

### 1. Get the GitLab Personal Access Token

![Get the GitLab Personal Access Token Steps](docs/image-1.png)

Please note the token must have the `api` scope. This GitLab account will post comments when reviewing MRs. So please remember the GitLab account name.

The token will be used as `GITLAB_PRIVATE_TOKEN` and the account name will be used as `GITLAB_REVIEWER_USERNAME`.

### 2. Import the workflow into Dify

Select the file `dify-workflow.yml` to import.

![How to import the workflow](docs/image-3.png)

Then adjust your workflow environment variables.

![Dify workflow environment variables](docs/image-2.png)

Sample:

```
GITLAB_HOST = https://gitlab.your-company.com
GITLAB_PRIVATE_TOKEN = <The token you retrived from the first step>
GITLAB_REVIEWER_USERNAME = <The GitLab account name you retrived from the first step>
```

> The workflow is default using the [**Google Gemini 2.0 Flash Exp**](https://aistudio.google.com/apikey). You can change to any other LLM model.

### 3. Note down the URL and Key from Dify workflow

This is for autommatically trigger the workflow.  
Get the workflow URL, it will be refered as `DIFY_URL` in following steps. It looks like:

```
https://your-dify-host/v1/workflows/run
```

And the API key from the workflow page, it will be refered as `DIFY_API_KEY` in follwoing steps:
![The Dify API Key](docs/image-4.png)

You will need the URL and API key to trigger the workflow.

### 4. Setup the trigger service.

Build the docker image:

```sh
cd trigger
docker build -t gitlab-mr-reviewer .
```

Run the docker container. The host should be accessible from the GitLab server.

```sh
docker run --name ai-code-review-trigger -d --restart always -p 4195:4195 -v $(pwd)/logs:/var/log/supervisor/ gitlab-mr-reviewer
```

Your GitLab server should be able to access this 4195 port. For example `http://localhost:4195`.

### 5. Setup a System Hook to GitLab

Go to your GitLab admin area, navigate to `System hooks > Add new webhook`.

Fill up the **URL** as `http://localhost:4195/hook?dify=<DIFY_URL>`

Fill up the **Secret token** as `<DIFY_API_KEY>` (it will be masked as ***)

Triggers should be `Merge request events` only.

Then click `Add webhook` to save the settings.

### 6. Done

That's all settings. You can try to create a new merge request and see what the AI would say!

## Contributing

Contributions are welcome! Please read the [contributing guidelines](CONTRIBUTING.md) to get started.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
