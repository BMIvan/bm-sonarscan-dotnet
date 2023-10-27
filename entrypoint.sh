#!/bin/bash -l
set -o pipefail
set -eu

# Creating a Docker container action - https://docs.github.com/en/actions/creating-actions/creating-a-docker-container-action
# Make entrypoint.sh file executable:
#  git update-index --chmod=+x entrypoint.sh
# 
# Check permission (it should start with 100755 where 755 are the attributes for an exexutable file):
#  git update-index --chmod=+x entrypoint.sh

# Check required parameters has a value
if [ -z "$INPUT_SONARPROJECTKEY" ]; then
  echo "Input parameter sonarProjectKey is required"
  exit 1
fi
if [ -z "$INPUT_SONARPROJECTNAME" ]; then
  echo "Input parameter sonarProjectName is required"
  exit 1
fi
if [ -z "$GH_PAT_CLASSIC" ]; then
  echo "Environment parameter GH_PAT_CLASSIC is required"
  exit 1
fi
if [ -z "$SONAR_TOKEN" ]; then
  echo "Environment parameter SONAR_TOKEN is required"
  exit 1
fi

# List Environment variables that's set by Github Action input parameters (defined by user)
echo "Github Action input parameters"
echo "INPUT_SONARORGANIZATION: $INPUT_SONARORGANIZATION"
echo "INPUT_SONARPROJECTKEY: $INPUT_SONARPROJECTKEY"
echo "INPUT_SONARPROJECTNAME: $INPUT_SONARPROJECTNAME"
echo "INPUT_SONARHOSTNAME: $INPUT_SONARHOSTNAME"
echo "INPUT_SONARBEGINARGUMENTS: $INPUT_SONARBEGINARGUMENTS"
echo "INPUT_DOTNETPREBUILDCMD: $INPUT_DOTNETPREBUILDCMD"
echo "INPUT_DOTNETBUILDARGUMENTS: $INPUT_DOTNETBUILDARGUMENTS"
echo "INPUT_DOTNETTESTARGUMENTS: $INPUT_DOTNETTESTARGUMENTS"
echo "INPUT_DOTNETDISABLETESTS: $INPUT_DOTNETDISABLETESTS"

# Environment variables that need to be mapped in Github Action
#     env:
#       GH_PAT_CLASSIC: "${{ secrets.GH_PAT_CLASSIC }}"
#       SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
#       GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
#
# GH_PAT_CLASSIC=[github_pat_classic]
# SONAR_TOKEN=[sonarqube_token]
# GITHUB_TOKEN=[github_token]

# Environment variables automatically set by Github Actions automatically passed on to the docker container
#
# Example pull request
# GITHUB_REPOSITORY=owner/repo
# GITHUB_EVENT_NAME=pull_request
# GITHUB_REF=refs/pull/1/merge
# GITHUB_HEAD_REF=somenewcodewithouttests
# GITHUB_BASE_REF=main
#
# Example normal push
# GITHUB_REPOSITORY=owner/repo
# GITHUB_EVENT_NAME="push"
# GITHUB_REF=refs/heads/main
# GITHUB_HEAD_REF=""
# GITHUB_BASE_REF=""

# ---------------------------------------------
# DEBUG: How to run container manually
# ---------------------------------------------
# export GH_PAT_CLASSIC=[github_pat_classic]
# export SONAR_TOKEN="sonarqube_token"

# Simulate Github Action input variables
# export INPUT_SONARORGANIZATION="organization"
# export INPUT_SONARPROJECTKEY="projectkey"
# export INPUT_SONARPROJECTNAME="projectname"
# export INPUT_SONARHOSTNAME="https://sonarcloud.io"
# export INPUT_SONARBEGINARGUMENTS=""
# export INPUT_DOTNETPREBUILDCMD=""
# export INPUT_DOTNETBUILDARGUMENTS=""
# export INPUT_DOTNETTESTARGUMENTS=""
# export INPUT_DOTNETDISABLETESTS=""

# Simulate Github Action built-in environment variables
# export GITHUB_REPOSITORY=owner/repo
# export GITHUB_EVENT_NAME="push"
# export GITHUB_REF=refs/heads/main
# export GITHUB_SHA="GUID (40 char)"
# export GITHUB_HEAD_REF=""
# export GITHUB_BASE_REF=""
#
# Build local Docker image
# docker build -t bm-sonarscan-dotnet .
# Execute Docker container
# docker run --name bm-sonarscan-dotnet -w /github/workspace --rm \
#   -e INPUT_SONARORGANIZATION \
#   -e INPUT_SONARPROJECTKEY \
#   -e INPUT_SONARPROJECTNAME \
#   -e INPUT_SONARHOSTNAME \
#   -e INPUT_SONARBEGINARGUMENTS \
#   -e INPUT_DOTNETPREBUILDCMD \
#   -e INPUT_DOTNETBUILDARGUMENTS \
#   -e INPUT_DOTNETTESTARGUMENTS \
#   -e INPUT_DOTNETDISABLETESTS \
#   -e GH_PAT_CLASSIC \
#   -e SONAR_TOKEN \
#   -e GITHUB_EVENT_NAME \
#   -e GITHUB_REPOSITORY \
#   -e GITHUB_REF \
#   -e GITHUB_SHA \
#   -e GITHUB_HEAD_REF \
#   -e GITHUB_BASE_REF \
#   -v "/var/run/docker.sock":"/var/run/docker.sock" \
#   -v $(pwd):"/github/workspace" \
#   bm-sonarscan-dotnet

#-----------------------------------
# Build Sonarscanner begin command
#-----------------------------------
sonar_begin_cmd="/dotnet-sonarscanner begin /k:\"${INPUT_SONARPROJECTKEY}\" /n:\"${INPUT_SONARPROJECTNAME}\" /d:sonar.token=\"${SONAR_TOKEN}\" /d:sonar.host.url=\"${INPUT_SONARHOSTNAME}\""
if [ -n "$INPUT_SONARORGANIZATION" ]; then
  sonar_begin_cmd="$sonar_begin_cmd /o:\"${INPUT_SONARORGANIZATION}\""
fi
if [ -n "$INPUT_SONARBEGINARGUMENTS" ]; then
  sonar_begin_cmd="$sonar_begin_cmd $INPUT_SONARBEGINARGUMENTS"
fi

# Check Github environment variable GITHUB_EVENT_NAME to determine if this is a pull request or not.
if [[ $GITHUB_EVENT_NAME == 'pull_request' ]]; then
  # Sonarqube wants these variables if build is started for a pull request
  # Sonarcloud parameters: https://sonarcloud.io/documentation/analysis/pull-request/
  # sonar.pullrequest.key               Unique identifier of your PR. Must correspond to the key of the PR in GitHub or TFS. E.G.: 5
  # sonar.pullrequest.branch            The name of your PR Ex: feature/my-new-feature
  # sonar.pullrequest.base              The long-lived branch into which the PR will be merged. Default: main E.G.: main
  # sonar.pullrequest.github.repository SLUG of the GitHub Repo (owner/repo)

  # Extract Pull Request numer from the GITHUB_REF variable
  PR_NUMBER=$(echo $GITHUB_REF | awk 'BEGIN { FS = "/" } ; { print $3 }')

  # Add pull request specific parameters in sonar scanner
  sonar_begin_cmd="$sonar_begin_cmd /d:sonar.pullrequest.key=$PR_NUMBER /d:sonar.pullrequest.branch=$GITHUB_HEAD_REF /d:sonar.pullrequest.base=$GITHUB_BASE_REF /d:sonar.pullrequest.github.repository=$GITHUB_REPOSITORY /d:sonar.pullrequest.provider=github"
fi

#-----------------------------------
# Build Sonarscanner end command
#-----------------------------------
sonar_end_cmd="/dotnet-sonarscanner end /d:sonar.token=\"${SONAR_TOKEN}\""

#-----------------------------------
# Build pre build command
#-----------------------------------
dotnet_prebuild_cmd="echo NO_PREBUILD_CMD"
if [ -n "$INPUT_DOTNETPREBUILDCMD" ]; then
  dotnet_prebuild_cmd="$INPUT_DOTNETPREBUILDCMD"
fi

#-----------------------------------
# Build dotnet build command
#-----------------------------------
dotnet_build_cmd="dotnet build"
if [ -n "$INPUT_DOTNETBUILDARGUMENTS" ]; then
  dotnet_build_cmd="$dotnet_build_cmd $INPUT_DOTNETBUILDARGUMENTS"
fi

#-----------------------------------
# Build dotnet test command
#-----------------------------------
dotnet_test_cmd="dotnet test"
if [ -n "$INPUT_DOTNETTESTARGUMENTS" ]; then
  dotnet_test_cmd="$dotnet_test_cmd $INPUT_DOTNETTESTARGUMENTS"
fi

#-----------------------------------
# Execute shell commands
#-----------------------------------
echo "Shell commands"

#Run Sonarscanner .NET Core "begin" command
echo "sonar_begin_cmd: $sonar_begin_cmd"
sh -c "$sonar_begin_cmd"

#Run dotnet pre build command
echo "dotnet_prebuild_cmd: $dotnet_prebuild_cmd"
sh -c "${dotnet_prebuild_cmd}"

#Run dotnet build command
echo "dotnet_build_cmd: $dotnet_build_cmd"
sh -c "${dotnet_build_cmd}"

#Run dotnet test command (unless user choose not to)
if ! [[ "${INPUT_DOTNETDISABLETESTS,,}" == "true" || "${INPUT_DOTNETDISABLETESTS}" == "1" ]]; then
  echo "dotnet_test_cmd: $dotnet_test_cmd"
  sh -c "${dotnet_test_cmd}"
fi

#Run Sonarscanner .NET Core "end" command
echo "sonar_end_cmd: $sonar_end_cmd"
sh -c "$sonar_end_cmd"

#--------------------------------------
# Get SonarCloud Code Analysis html url
#--------------------------------------
# Login to GitHub api
#echo $GH_PAT_CLASSIC | gh auth login --with-token

# Get Commit info
GITHUB_BASEURL=https://api.github.com
GITHUB_API=repos/$GITHUB_REPOSITORY/commits/$GITHUB_SHA/check-runs
echo "GITHUB_BASEURL: $GITHUB_BASEURL"
echo "GITHUB_REPOSITORY: $GITHUB_REPOSITORY"
echo "GITHUB_SHA: $GITHUB_SHA"
echo "GITHUB_API: $GITHUB_API"

# GitHub CLI - Could not get GitHub login working 'gh auth login'
# json_data=$(gh api $GITHUB_API)

# GitHub API
json_data=$(curl --get -Ss -H "Authorization: Bearer ${GH_PAT_CLASSIC}" -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" "${GITHUB_BASEURL}/${GITHUB_API}")
#echo "json_data: $json_data"

if [ -z "$json_data" ]; then
  echo "json_data is empty."
  exit 1
fi

# Find check_runs[].name = "SonarCloud Code Analysis" and get 'html_url' field
html_url=$(jq -r '.check_runs[] | select(.name == "SonarCloud Code Analysis").html_url' <<< "$json_data")
echo "html_url: $html_url"

if [ -z "$html_url" ]; then
  echo "html_url is empty."
  exit 1
fi

echo $html_url
echo "html_url=$html_url" >> $GITHUB_OUTPUT
