# Docker image for Petals Deployer

This image allows to configure and run a Petals CLI instance to deploy artifacts onto a running Petals ESB instance.

Connection parameters and artifact list must be set at launch.
Artifacts can be deployed by 
* mounting a docker volume containnig artifacts zipfiles and giving files to deploy. (Only works when the deployer and Petals are running on the same machine.)
* hosting artifacts on a nexus or any web server and giving artifacts url.
>Both method can be used at once but artifacts as parameters will always be deployed first.


## Launch a container from this image

```properties
# Download the image
docker pull petalslink/petals-deployer:latest

# Start in detached mode (with default config)
docker run -d -p 80:80 --name petals-deployer petalslink/petals-deployer:latest

# Start example #1
docker run \
	-d -p 80:80 --name petals-deployer \
	-v /home/user/Petals/artifacts/:/tmp/artifact/ \
	-e "ENV_DEPLOY_FILE=/tmp/artifact/filesToDeploy.txt" \
	-e "ENV_CLI_HOST=172.17.0.2" \
	petalslink/petals-deployer:latest

# Start example #2
docker run \
	-d --name petals-deployer \
	-e "ENV_CLI_HOST=172.17.0.5" \
	-e "ENV_DEPLOY_URLS=mvn:org.ow2.petals/petals-bc-soap/LATEST/zip;mvn:org.ow2.petals/petals-bc-ftp/LATEST/zip" \
	petalslink/petals-deployer:5.2.0

# Verify the container was launched
docker ps

# Watch what happens/happened
docker logs petals-deployer

# Verify the ports used on the host (example)
sudo lsof -i :80

# Get information about the container
docker inspect petals-deployer

# Introspect the container
docker exec -ti petals-deployer /bin/bash
```

The example shows how to get the last version.
You can obviously change the version. Each Petals container release has a corresponding deployer release, with a matching version. As an example, to get a deployer for **Petals ESB 5.1.0** (which would actually be **Petals CLI 3.0.0**), just type in `docker pull petalslink/petals-deployer:5.1.0`.
> You can choose a specific **Petals CLI** version by building your own image

## Run parameters

When running this deployer, you must specify it which artifacts to deploy and on which Petals ESB container instance.
> Please note that service assemblies require components which may require shared libraries. Be sure to deploy in the correct order. Every artifact will be started (if possible) after being deployed.     

You can use the following parameters:

| Argument | Optional | Default | Description |
| -------- | :------: | :-----: | ----------- |
| CLI_PETALS_HOST | yes | `172.17.0.1` | The petals container hostname. |
| CLI_PETALS_PORT | yes | `7700` | The petals container JMX port. |
| CLI_PETALS_USER | yes | `petals` | The petals container user to use. |
| CLI_PETALS_PASS | yes | `petals` | The petals container password to use.  |
| DEPLOY_URLS | this and/or DEPLOY_FILE must be set | - | The artifact list (as String) to be deployed, separated by the semicolon character (`;`). This artifact list will be processed **before** DEPLOY_FILE. **A valid CLI *deploy* format is expected, see below.**  Example: `mvn:<url1>;mvn:<url2>;file:<file1>` |
| DEPLOY_FILE | this and/or DEPLOY_URLS must be set | - | The artifact list (as file) to be deployed, each file line is treated separately. Remember that to be able to access a local file, **a volume has to be mounted**. This artifact list will be processed **after** DEPLOY_URLS. **A valid CLI *deploy* format is expected, see below.** Example: `/tmp/artifact/filesToDeploy.txt`|

In order to access local files or artifacts when running docker you have to share space with the docker container. For instance using volumes like `-v <localPath>:<pathVisibleInsideDocker>`. See [docker documentation](https://docs.docker.com/storage/volumes/). Only works when the deployer and Petals are running on the same machine!

The port 80 (which can be opened adding `-p 80:80` to the run command) is necessary only when there are local zipped files. Otherwise, it is not used.

### Petals CLI deploy format:
This is a valid format :
```
<artifact-file> [-f,--file <configuration-file> | -D <configuration-properties>] [-s,--skip-startup]
```
* **artifact-file:**  is the local file name or the URL correctly encoded of the artifact to install or deploy and start. 
	* *mvn uri*: Correct format is `mvn:[<repository-url>!] <group-id>/<artifact-id> [/[version] [/[<type>] [/<classifier>]]]]`    
	example : `
mvn:http://repository.ops4j.org/maven2!org.ops4j.pax.web.bundles/service/0.2.0` (see [maven uri](https://ops4j1.jira.com/wiki/spaces/paxurl/pages/3833866/Mvn+Protocol))
	* *file uri*: Correct format is `file://host/path` (host can be ignored if local)    
	example: `file:///etc/fstab` (see [file uri](https://en.wikipedia.org/wiki/File_URI_scheme))
* **configuration-file:**  is the local file name or the URL correctly encoded of the properties file used to configure the artifact.
* **configuration-properties:**  is a list of `<property-name>=<property-value>`, separated by a comma, where `<property-name>` is the name of the property to configure with `<property-value>`.  This argument is exclusive with` <configuration-file>`
* If the flag **-s,--skip-startup** is set, the start-up of the artifact is skipped, the artifact is only deployed.

> Note: `<configuration-file>` and `<configuration-properties>` arguments are used only if the artifact is a component. It has no sense for other artifacts.

When using `DEPLOY_URLS`, only a sequence of `<artifact-file>` can be used.  
When using `DEPLOY_FILE`, each line in the file is processed separately and thus optional arguments af `-f -D` or `-s` can be used.

To learn [more about deploy](https://doc.petalslink.com/pages/viewpage.action?pageId=21103359#PetalsCLI3.1.0%2B-DeployingandStartinganArtifactatonce).

## Run with parameters full example
Here is an example using all parameters:

```
docker run \
	-d -p 80:80 --name petals-deployer \
	-v /home/user/Petals/artifacts/:/tmp/artifact/ \
	-e "ENV_CLI_HOST=172.17.0.2" \
	-e "CLI_PETALS_HOST=172.23.0.8" \
	-e "CLI_PETALS_PORT=7701" \
	-e "CLI_PETALS_USER=petalsUser"
	-e "CLI_PETALS_PASS=unbreakablePassword" \
	-e "ENV_DEPLOY_FILE=/tmp/artifact/filesToDeploy.txt" \
	-e "ENV_DEPLOY_URLS=mvn:org.ow2.petals/petals-bc-soap/LATEST/zip;mvn:org.ow2.petals/petals-bc-ftp/LATEST/zip;mvn:org.ow2.petals/petals-se-flowable/LATEST/zip" \
	petalslink/petals-deployer:5.2.0
```
example of `filesToDeploy.txt` content :
```
file:///tmp/artifact/petals-sl-mandatory-9.6.0.6.zip
file:///tmp/artifact/petals-bc-rest-2.0.5.zip -D /tmp/artifacts/config/bc-rest.properties
file:///tmp/artifact/sa-REST-ServicePack35-provide-5.2.0.6.zip
file:///tmp/artifact/sa-REST-ServiceSomething-consume-6.5.1.zip

```
Of course for this to work correctly `/home/user/Petals/artifacts/` should contain all .zip and the .txt files given as parameters.
## Build an image (introduction)

This project allows to build a Docker image for both released and snapshot versions of Petals CLI. 
>Note: Petals deployer docker images realeases are aligned along with petals ESB releases, following Petals ESB versions. Building your own deployer image alows you to choose Petals CLI version.   

The process is a little bit different for each case. All of this relies on Docker build arguments and the presence
of the package in OW2's Maven repository (which is currently [Nexus](https://www.sonatype.com/nexus-repository-sonatype)).

| Argument | Optional | Default | Description |
| -------- | :------: | :-----: | ----------- |
| CLI_VERSION | yes | LATEST | The version of the Petals CLI distribution to use. It can include a "-SNAPSHOT" suffix. In this case, the Maven policy should be "snapshots" instead of "releases". **LATEST** is a special keyword for Nexus' API, which is used at build time to resolve the artifact to download. |
| MAVEN_POLICY | - | releases | The Maven policy: should we search in the `snapshots` or in the `releases` repository? |
| BASE_URL | yes |  [https://repository.ow2.org/ nexus/service/local/ artifact/maven/redirect](https://repository.ow2.org/nexus/service/local/artifact/maven/redirect) | The REST API used to resolve the Maven artifacts (the Debian packages are stored as Maven artifacts). One could reference another Nexus instance or [a mock of it](https://github.com/roboconf/dockerized-mock-for-nexus-api). |

By using these parameters correctly, you can achieve what you want, provided the packages are available in a Nexus repository.
Examples are given below.


## Build an image for a released version of Petals ESB

The example is quite simple to understand.

```
docker build \
		--build-arg CLI_VERSION=3.0.0 \
		-t petals/petals-deployer:latest \
		-t petals/petals-deployer:5.1.0 \
		.
```

The **latest** tag for Docker should only be used if this is the last released version of Petals deployer.

> As released version of petals-deployer follow Petals ESB version, it is recommended to follow this rule even for local builds.

## Build an image for a snapshot version of Petals ESB

Just like for a released version of Petals CLI, you need to know the version of Petals CLI to use.
It must also be available in a Nexus repository. If you built it on your local machine, it is possible
to mimic a Nexus repository thanks to [this project](https://github.com/roboconf/dockerized-mock-for-nexus-api)
(that will pick up the artifacts to download in your local Maven repository).

You can then launch the build process with...

```
docker build \
		--build-arg CLI_VERSION=3.1.0-SNAPSHOT \
		--build-arg MAVEN_POLICY=snapshots \
		-t petals/petals-deployer:5.2.0-SNAPSHOT \
		.
```

Such images should not be shared on Petals's official repository.


## Publish the image on Docker Hub

This section is obviously reserved to those that have access to the petals organization.  
**It is assumed you already built the image locally and tested it.**
> **Warning:** Remember that petals-deployer images are published under the Petals ESB version they are compatible with, not the Petals CLI version they are using! 
```properties
# Define your properties
DOCKER_HUB_USER=""
DOCKER_HUB_PWD=""
PETALS_VERSION="5.1.0"

# Connect to the hub
docker login -u=${DOCKER_HUB_USER} -p=${DOCKER_HUB_PWD}

# Push the image
docker push petals/petals-deployer:${PETALS_VERSION}
docker push petals/petals-deployer:latest

# Log out
docker logout

# Tag the Git repository
git tag -a -f "docker-petals-deployer-${PETALS_VERSION}" -m "Dockerfile for Petals ESB ${RELEASE_VERSION}"
git push --tags origin master
```


## Supported Docker versions

This image is officially supported on Docker version 1.9.0 and higher.  
Please see [the Docker installation documentation](https://docs.docker.com/install/)
for details on how to upgrade your Docker daemon.


## License

These images are licensed under the terms of the [LGPL 2.1](https://www.gnu.org/licenses/old-licenses/lgpl-2.1.fr.html).


## Documentation

Documentation for Petals CLI can be found on [its wiki](https://doc.petalslink.com/pages/viewpage.action?pageId=21103359). (Mind CLI version, this is for the `3.1.0+`)  
Documentation for Petals ESB can be found on [its wiki](https://doc.petals.com).   
You can also visit [its official web site](http://petals.ow2.org).
