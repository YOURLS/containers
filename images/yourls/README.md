# YOURLS

> [YOURLS](https://yourls.org/) is a set of PHP scripts that will allow you to run Your Own URL Shortener.

## About

This image contains the [YOURLS](https://yourls.org) app to be used as a container.

It includes the [PHP engine](https://hub.docker.com/_/php) which is required for
bootstrapping a running deployment for the requirements of the YOURLS application.

| Registry | Image |
|:--------:|:-----:|
| Docker Hub ["Official Image"](https://docs.docker.com/docker-hub/official_repos/) | [`docker.io/library/yourls` (`yourls`)](https://hub.docker.com/_/yourls) |
| GitHub Container Registry | [`ghcr.io/yourls/yourls`](https://github.com/YOURLS/YOURLS/pkgs/container/yourls) |

## Prerequisites

* A container engine

## Usage

### Start a YOURLS instance

```bash
docker run \
    --name some-yourls \
    --detach \
    --link some-mysql:mysql \
    --env YOURLS_SITE="https://example.com" \
    --env YOURLS_USER="example_username" \
    --env YOURLS_PASS="example_password" \
    yourls
```

The YOURLS instance accepts a number of environment variables for configuration, see [_Environment Variables_](#environment-variables) section below.

If you'd like to use an external database instead of a linked `mysql` container, specify the hostname and port with `YOURLS_DB_HOST` along with the password in `YOURLS_DB_PASS` and the username in `YOURLS_DB_USER` (if it is something other than `root`):

```bash
docker run \
    --name some-yourls \
    --detach \
    --env YOURLS_DB_HOST=10.1.2.3:3306 \
    --env YOURLS_SITE="https://example.com" \
    --env YOURLS_USER="example_username" \
    --env YOURLS_PASS="example_password" \ 
    yourls
```

### Connect to the YOURLS administration interface

If you'd like to be able to access the instance from the host without the container's IP, standard port mappings can be used:

```bash
docker run \
    --name some-yourls \
    --detach \
    --link some-mysql:mysql \
    --publish 8080:80 \
    yourls
```

Then, access it via `http://localhost:8080/admin/` or `http://<host-ip>:8080/admin/` in a browser.

> **Note** On first instantiation, reaching the root folder will generate an error. Access the YOURLS administration interface via the path `/admin/`.

## Environment Variables

When you start the `yourls` image, you can adjust the configuration of the YOURLS instance by passing one or more environment variables on the `docker run` command-line.  
The YOURLS instance accepts [a number of environment variables for configuration](https://yourls.org/#Config).  
A few notable/important examples for using this Docker image include the following.

### `YOURLS_SITE`

**Required.**  
YOURLS instance URL, no trailing slash, lowercase.

Example: `YOURLS_SITE="https://example.com"`

### `YOURLS_USER`

**Required.**  
YOURLS instance username.

Example: `YOURLS_USER="example_username"`

### `YOURLS_PASS`

**Required.**  
YOURLS instance password.

Example: `YOURLS_PASS="example_password"`

### `YOURLS_DB_HOST`, `YOURLS_DB_USER`, `YOURLS_DB_PASS`

**Optional if linked `mysql` container.**

Host, user (defaults to `root`) and password for the database.

### `YOURLS_DB_NAME`

**Optional.**  
Database name, defaults to `yourls`. The database must have been created before installing YOURLS.

### `YOURLS_DB_PREFIX`

**Optional.**  
Database tables prefix, defaults to `yourls_`. Only set this when you need to override the default table prefix.

## Docker Secrets

As an alternative to passing sensitive information via environment variables, `_FILE` may be appended to the previously listed environment variables, causing the initialization script to load the values for those variables from files present in the container. In particular, this can be used to load passwords from Docker secrets stored in `/run/secrets/<secret_name>` files. For example:

```bash
docker run \
    --name some-yourls \
    --detach \
    --env YOURLS_DB_PASS_FILE=/run/secrets/mysql-root \
    yourls
```

Currently, this is supported for `YOURLS_DB_HOST`, `YOURLS_DB_USER`, `YOURLS_DB_PASS`, `YOURLS_DB_NAME`, `YOURLS_DB_PREFIX`, `YOURLS_SITE`, `YOURLS_USER`, and `YOURLS_PASS`.

## Docker Compose

Example `docker-compose.yml` for `yourls`:

```yaml
version: '3.1'
services:
  yourls:
    image: yourls
    restart: always
    ports:
      - 8080:80
    environment:
      YOURLS_DB_PASS: example
      YOURLS_SITE: https://example.com
      YOURLS_USER: example_username
      YOURLS_PASS: example_password
  mysql:
    image: mysql
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: example
      MYSQL_DATABASE: yourls
```

[![Try in PWD](https://github.com/play-with-docker/stacks/raw/cff22438cb4195ace27f9b15784bbb497047afa7/assets/images/button.png)](http://play-with-docker.com?stack=https://raw.githubusercontent.com/YOURLS/images/main/stack.yml)

Run `docker compose -f stack.yml up`, wait for it to initialize completely, and visit `http://localhost:8080/admin/`, or `http://<host-ip>:8080/admin/` (as appropriate).

### Adding additional libraries / extensions

This image does not provide any additional PHP extensions or other libraries, even if they are required by popular plugins. There are an infinite number of possible plugins, and they potentially require any extension PHP supports. Including every PHP extension that exists would dramatically increase the image size.

If you need additional PHP extensions, you'll need to create your own image `FROM` this one. The [documentation of the `php` image](https://github.com/docker-library/docs/blob/master/php/README.md#how-to-install-more-php-extensions) explains how to compile additional extensions.

## Image Variants

The `yourls` images come in many flavors, each designed for a specific use case.

### `yourls:<version>`, `php:<version>-apache`

This is the defacto image. If you are unsure about what your needs are, you probably want to use this one. It is designed to be used both as a throw away container (mount your source code and start the container to start your app), as well as the base to build other images off of.

This image contains Debian's Apache httpd in conjunction with PHP (as `mod_php`) and uses `mpm_prefork` by default.

### `yourls:<version>-fpm`

This variant contains PHP-FPM, which is a FastCGI implementation for PHP. See [the PHP-FPM site](https://php-fpm.org/) for more information about PHP-FPM.

In order to use this image variant, some kind of reverse proxy (such as NGINX, Apache, or other tool which speaks the FastCGI protocol) will be required.

Some potentially helpful resources:

- [PHP-FPM.org](https://php-fpm.org/)
- [simplified example by @md5](https://gist.github.com/md5/d9206eacb5a0ff5d6be0)
- [very detailed article by Pascal Landau](https://www.pascallandau.com/blog/php-php-fpm-and-nginx-on-docker-in-windows-10/)
- [Stack Overflow discussion](https://stackoverflow.com/q/29905953/433558)
- [Apache httpd Wiki example](https://wiki.apache.org/httpd/PHPFPMWordpress)

> **Warning** The FastCGI protocol is inherently trusting, and thus _extremely_ insecure to expose outside of a private container network -- unless you know _exactly_ what you are doing (and are willing to accept the extreme risk), do not use Docker's `--publish` (`-p`) flag with this image variant.

### `yourls:<version>-alpine`

This image is based on the popular [Alpine Linux project](https://alpinelinux.org), available in [the `alpine` official image](https://hub.docker.com/_/alpine). Alpine Linux is much smaller than most distribution base images (~5MB), and thus leads to much slimmer images in general.

This variant is useful when final image size being as small as possible is your primary concern.
The main caveat to note is that it does use [musl libc](https://musl.libc.org) instead of [glibc and friends](https://www.etalabs.net/compare_libcs.html), so software will often run into issues depending on the depth of their libc requirements/assumptions.
See [this Hacker News comment thread](https://news.ycombinator.com/item?id=10782897) for more discussion of the issues that might arise and some pro/con comparisons of using Alpine-based images.

To minimize image size, it's uncommon for additional related tools (such as `git` or `bash`) to be included in Alpine-based images.
Using this image as a base, add the things you need in your own Dockerfile (see the [`alpine` image description](https://hub.docker.com/_/alpine/) for examples of how to install packages if you are unfamiliar).

## Docker Hub reference

[![Docker Hub Pulls](https://img.shields.io/docker/pulls/_/yourls.svg)](https://hub.docker.com/_/yourls)
[![Docker Hub Stars](https://img.shields.io/docker/stars/_/yourls.svg)](https://hub.docker.com/_/yourls)

### How to change README page visible on Docker Hub?

The [full description from Docker Hub](https://hub.docker.com/_/yourls) is generated over in [docker-library/docs](https://github.com/docker-library/docs), specifically in [docker-library/docs/yourls](https://github.com/docker-library/docs/tree/master/yourls).

### See a change merged here that doesn't show up on Docker Hub yet?

Check [the "library/yourls" manifest file in the docker-library/official-images repository](https://github.com/docker-library/official-images/blob/master/library/yourls), especially [PRs with the "library/yourls" label on that repository](https://github.com/docker-library/official-images/labels/library%2Fyourls).

For more information about the official images process, see the [docker-library/official-images readme](https://github.com/docker-library/official-images/blob/master/README.md).

### What are the architectures available on the Docker Hub?

| Build | Status | Badges | (per-arch) |
|:-:|:-:|:-:|:-:|
| [![amd64 build status badge](https://img.shields.io/jenkins/s/https/doi-janky.infosiftr.net/job/multiarch/job/amd64/job/yourls.svg?label=amd64)](https://doi-janky.infosiftr.net/job/multiarch/job/amd64/job/yourls/) | [![arm32v5 build status badge](https://img.shields.io/jenkins/s/https/doi-janky.infosiftr.net/job/multiarch/job/arm32v5/job/yourls.svg?label=arm32v5)](https://doi-janky.infosiftr.net/job/multiarch/job/arm32v5/job/yourls/) | [![arm32v6 build status badge](https://img.shields.io/jenkins/s/https/doi-janky.infosiftr.net/job/multiarch/job/arm32v6/job/yourls.svg?label=arm32v6)](https://doi-janky.infosiftr.net/job/multiarch/job/arm32v6/job/yourls/) | [![arm32v7 build status badge](https://img.shields.io/jenkins/s/https/doi-janky.infosiftr.net/job/multiarch/job/arm32v7/job/yourls.svg?label=arm32v7)](https://doi-janky.infosiftr.net/job/multiarch/job/arm32v7/job/yourls/) |
| [![arm64v8 build status badge](https://img.shields.io/jenkins/s/https/doi-janky.infosiftr.net/job/multiarch/job/arm64v8/job/yourls.svg?label=arm64v8)](https://doi-janky.infosiftr.net/job/multiarch/job/arm64v8/job/yourls/) | [![i386 build status badge](https://img.shields.io/jenkins/s/https/doi-janky.infosiftr.net/job/multiarch/job/i386/job/yourls.svg?label=i386)](https://doi-janky.infosiftr.net/job/multiarch/job/i386/job/yourls/) | [![mips64le build status badge](https://img.shields.io/jenkins/s/https/doi-janky.infosiftr.net/job/multiarch/job/mips64le/job/yourls.svg?label=mips64le)](https://doi-janky.infosiftr.net/job/multiarch/job/mips64le/job/yourls/) | [![ppc64le build status badge](https://img.shields.io/jenkins/s/https/doi-janky.infosiftr.net/job/multiarch/job/ppc64le/job/yourls.svg?label=ppc64le)](https://doi-janky.infosiftr.net/job/multiarch/job/ppc64le/job/yourls/) |
| [![s390x build status badge](https://img.shields.io/jenkins/s/https/doi-janky.infosiftr.net/job/multiarch/job/s390x/job/yourls.svg?label=s390x)](https://doi-janky.infosiftr.net/job/multiarch/job/s390x/job/yourls/) | [![put-shared build status badge](https://img.shields.io/jenkins/s/https/doi-janky.infosiftr.net/job/put-shared/job/light/job/yourls.svg?label=put-shared)](https://doi-janky.infosiftr.net/job/put-shared/job/light/job/yourls/) |

## License

This project is licensed under [MIT License](LICENSE).
