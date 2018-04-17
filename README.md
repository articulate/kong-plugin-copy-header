# kong-plugin-copy-header

## Overview

A [kong](https://getkong.org/) plugin for copying headers to a new header.  

This plugin can also be used for finding and copying the client IP in a header, storing it in a new header.

## Usage

The configuration, currently generated from [articulate-kong-config](https://github.com/articulate/articulate-kong-config), can take an array, or multiple arrays, as arguments to the headers config.  It expects keys of `original` and `new` with their values set to the name of the header we are to copy and the new header to store the data in, respectively.  It can optionally take the `client_ip_only` key with a boolean value which allows finding and copying of _only_ the client IP from the original header, given a comma separated string of ips.

For example, the following configuration will allow copying of only the client IP from the `x-forwarded-for` header into an `auth0-forwarded-for` header, as well as copying the `test1` header into a `test2` header, unmodified:

```
- name: 'test_api'
  attributes:
    upstream_url: 'http://upstream.url/here'
  plugins:
  - name: 'copy-header'
    attributes:
      config:
        headers:
          - original: "x-forwarded-for"
            new: "auth0-forwarded-for"
            client_ip_only: true
          - original: "test1"
            new: "test2"
```

## Development

https://docs.articulate.zone/how-do-i/run-my-service-locally.html

## Build

This plugin gets pulled in and built into our [articulate-kong](https://github.com/articulate/articulate-kong) image via its [Dockerfile](https://github.com/articulate/articulate-kong/blob/master/Dockerfile) and built using luarocks.

## Tests

Tests can be ran with: `docker-compose run --rm app make jenkins`
