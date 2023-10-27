# SonarScanner for .NET

SonarScanner for .NET for use in Github Actions, with automatic pull request detection, analysis and decoration.

## Usage examples

### Simple use with SonarCloud

``` yaml
env:
  SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
  GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

    - name: SonarScanner for .NET
      uses: bmivan/bm-sonarscan-dotnet@latest
      with:
        # The key of the SonarQube project
        sonarProjectKey: projectkey

        # The name of the SonarQube project
        sonarProjectName:  projectname

        # The name of the SonarQube organization in SonarCloud. For hosted SonarQube, skip this setting.
        sonarOrganization: organization

```

### Include code coverage with [Coverlet](https://github.com/coverlet-coverage/coverlet)

Also includes test results.

``` yaml
env:
  SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
  GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

    - name: SonarScanner for .NET
      uses: bmivan/bm-sonarscan-dotnet@latest
      with:
        # The key of the SonarQube project
        sonarProjectKey: projectkey

        # The name of the SonarQube project
        sonarProjectName:  projectname

        # The name of the SonarQube organization in SonarCloud. For hosted SonarQube, skip this setting.
        sonarOrganization: organization

        # Optional command arguments to dotnet test
        dotnetTestArguments: --logger trx --collect:"XPlat Code Coverage" -- DataCollectionRunSettings.DataCollectors.DataCollector.Configuration.Format=opencover

        # Optional extra command arguments the the SonarScanner 'begin' command
        sonarBeginArguments: /d:sonar.cs.opencover.reportsPaths="**/TestResults/**/coverage.opencover.xml" -d:sonar.cs.vstest.reportsPaths="**/TestResults/*.trx"
```

### Build subfolder src, and include code coverage

Also includes test results.

``` yaml
env:
  SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
  GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

    - name: SonarScanner for .NET
      uses: bmivan/bm-sonarscan-dotnet@latest
      with:
        # The key of the SonarQube project
        sonarProjectKey: projectkey

        # The name of the SonarQube project
        sonarProjectName:  projectname

        # The name of the SonarQube organization in SonarCloud. For hosted SonarQube, skip this setting.
        sonarOrganization: organization

        # Optional command arguments to dotnet build
        dotnetBuildArguments: ./src

        # Optional command arguments to dotnet test
        dotnetTestArguments: ./src --logger trx --collect:"XPlat Code Coverage" -- DataCollectionRunSettings.DataCollectors.DataCollector.Configuration.Format=opencover

        # Optional extra command arguments the the SonarScanner 'begin' command
        sonarBeginArguments: /d:sonar.cs.opencover.reportsPaths="**/TestResults/**/coverage.opencover.xml" -d:sonar.cs.vstest.reportsPaths="**/TestResults/*.trx"
```

### Skip tests

``` yaml
env:
  SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
  GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

    - name: SonarScanner for .NET
      uses: bmivan/bm-sonarscan-dotnet@latest
      with:
        # The key of the SonarQube project
        sonarProjectKey: projectkey

        # The name of the SonarQube project
        sonarProjectName:  projectname

        # The name of the SonarQube Organization
        sonarOrganization: organization

        # Optional. Set to 1 or true to not run 'dotnet test' command
        dotnetDisableTests: true        
```

### Use pre-build command to add a custom NuGet repository

``` yaml
env:
  SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
  GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

    - name: SonarScanner for .NET
      uses: bmivan/bm-sonarscan-dotnet@latest
      with:
        # The key of the SonarQube project
        sonarProjectKey: projectkey

        # The name of the SonarQube project
        sonarProjectName:  projectname

        # The name of the SonarQube organization in SonarCloud. For hosted SonarQube, skip this setting.
        sonarOrganization: organization

        # Optional command to run before 'dotnet build'. This example adds a NuGet source for other private GitHub Packages registry.
        dotnetPreBuildCmd: dotnet nuget add source --username github_user --password ${{ secrets.MY_PAT_TOKEN }} --store-password-in-clear-text --name github "https://nuget.pkg.github.com/OWNER/index.json"

        # Optional command arguments to dotnet build
        dotnetBuildArguments: ./src
```

### Use with self-hosted SonarQube

``` yaml
env:
  SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
  GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

    - name: SonarScanner for .NET
      uses: bmivan/bm-sonarscan-dotnet@latest
      with:
        # The key of the SonarQube project
        sonarProjectKey: projectkey

        # The name of the SonarQube project
        sonarProjectName:  projectname

        # The SonarQube server URL. For SonarCloud, skip this setting.
        sonarHostname:  selfhosted_sonarqube_hostname
```

## Secrets

- `SONAR_TOKEN` – **Required** this is the token used to authenticate access to SonarCloud. You can generate a token on your [Security page in SonarCloud](https://sonarcloud.io/account/security/). You can set the `SONAR_TOKEN` environment variable in the "Secrets" settings page of your repository.
- *`GITHUB_TOKEN` – Provided by Github (see [Authenticating with the GITHUB_TOKEN](https://help.github.com/en/actions/automating-your-workflow-with-github-actions/authenticating-with-the-github_token)).*

## Description of all inputs

``` yaml
inputs:
  sonarProjectKey:
    description: "The key of the SonarQube project"
    required: true
  sonarProjectName:
    description: "The name of the SonarQube project"
    required: true
  sonarOrganization:
    description: "The name of the SonarQube organization in SonarCloud. For hosted SonarQube, skip this setting."
    required: false
  dotnetBuildArguments:
    description: "Optional command arguments to 'dotnet build'"
    required: false
  dotnetPreBuildCmd:
    description: "Optional command run before the 'dotnet build'"
    required: false    
  dotnetTestArguments:
    description: "Optional command arguments to 'dotnet test'"
    required: false
  dotnetDisableTests:
    description: "Optional. Set to 1 or true to not run 'dotnet test' command"
    required: false
  sonarBeginArguments:
    description: "Optional extra command arguments the the SonarScanner 'begin' command"
    required: false
  sonarHostname:
    description: "The SonarQube server URL. For SonarCloud, skip this setting."
    default: "https://sonarcloud.io"
    required: false
```

## Troubleshooting

### Build error "ERROR: Could not find a default branch to fall back on."

If this error occurs in the build log, you can try this:

- You may have to manually create the project in SonarQube/SonarCloud dashboard first. Make sure the Action input parameter sonarProjectKey (and sonarOrganization for SonarCloud) matches the ones in SonarQube/SonarCloud.
- Make sure you have correct SONAR_TOKEN set. See [Secrets](#secrets) above.

### SonarQube/SonarCloud dashboard warning "Shallow clone detected during the analysis..."

If the SonarQube/SonarCloud dashboard shows a warning message in the top right ("Last analysis had x warning"), and the message is

`"Shallow clone detected during the analysis. Some files will miss SCM information. This will affect features like auto-assignment of issues. Please configure your build to disable shallow clone."`

it can be fixed by modifying the Git checkout action fetch-depth parameter: 

``` yaml
- uses: actions/checkout@v2
      with:
        fetch-depth: '0'
```
