[![Puppet Forge Version](http://img.shields.io/puppetforge/v/herculesteam/augeasproviders_apache.svg)](https://forge.puppetlabs.com/herculesteam/augeasproviders_apache)
[![Puppet Forge Downloads](http://img.shields.io/puppetforge/dt/herculesteam/augeasproviders_apache.svg)](https://forge.puppetlabs.com/herculesteam/augeasproviders_apache)
[![Puppet Forge Endorsement](https://img.shields.io/puppetforge/e/herculesteam/augeasproviders_apache.svg)](https://forge.puppetlabs.com/herculesteam/augeasproviders_apache)
[![Build Status](https://img.shields.io/travis/hercules-team/augeasproviders_apache/master.svg)](https://travis-ci.org/hercules-team/augeasproviders_apache)
[![Coverage Status](https://img.shields.io/coveralls/hercules-team/augeasproviders_apache.svg)](https://coveralls.io/r/hercules-team/augeasproviders_apache)
[![Gemnasium](https://img.shields.io/gemnasium/hercules-team/augeasproviders_apache.svg)](https://gemnasium.com/hercules-team/augeasproviders_apache)


# apache: types/providers for apache files for Puppet

This module provides new types/providers for Puppet to read and modify apache
config files using the Augeas configuration library.

The advantage of using Augeas over the default Puppet `parsedfile`
implementations is that Augeas will go to great lengths to preserve file
formatting and comments, while also failing safely when needed.

This provider will hide *all* of the Augeas commands etc., you don't need to
know anything about Augeas to make use of it.

## Requirements

Ensure both Augeas and ruby-augeas 0.3.0+ bindings are installed and working as
normal.

See [Puppet/Augeas pre-requisites](http://docs.puppetlabs.com/guides/augeas.html#pre-requisites).

## Installing

On Puppet 2.7.14+, the module can be installed easily ([documentation](http://docs.puppetlabs.com/puppet/latest/reference/modules_installing.html)):

    puppet module install herculesteam/augeasproviders_apache

You may see an error similar to this on Puppet 2.x ([#13858](http://projects.puppetlabs.com/issues/13858)):

    Error 400 on SERVER: Puppet::Parser::AST::Resource failed with error ArgumentError: Invalid resource type `apache_directive` at ...

Ensure the module is present in your puppetmaster's own environment (it doesn't
have to use it) and that the master has pluginsync enabled.  Run the agent on
the puppetmaster to cause the custom types to be synced to its local libdir
(`puppet master --configprint libdir`) and then restart the puppetmaster so it
loads them.

## Compatibility

### Puppet versions

Minimum of Puppet 2.7.

### Augeas versions

Augeas Versions           | 0.10.0  | 1.0.0   | 1.1.0   | 1.2.0   |
:-------------------------|:-------:|:-------:|:-------:|:-------:|
**FEATURES**              |
case-insensitive keys     | no      | **yes** | **yes** | **yes** |
**PROVIDERS**             |
apache\_directive         | **yes** | **yes** | **yes** | **yes** |
apache\_setenv            | **yes** | **yes** | **yes** | **yes** |

## Documentation and examples

Type documentation can be generated with `puppet doc -r type` or viewed on the
[Puppet Forge page](http://forge.puppetlabs.com/herculesteam/augeasproviders_apache).

### apache_directive provider

#### Composite namevars
This type supports composite namevars in order to easily specify the entry you want to manage.  The format is:
    <directive> of <context>
or
    <directive> of <context> in <target>

#### manage simple entry

    apache_directive { "StartServers":
      args   => 4,
      ensure => present,
    }

#### delete entry

    apache_directive { "ServerName":
      args   => "foo.example.com",
      ensure => absent,
    }

#### manage entry in another config location

    apache_directive { "SetEnv":
      args        => ["SPECIAL_PATH", "/foo/bin"],
      args_params => 1,
      ensure      => present,
      target      => "/etc/httpd/conf.d/app.conf",
    }

The `SetEnv` directive is not unique per scope: the first arg identifies the entry we want to update, and needs to be taken into account. For this reason, we set `args_params` to `1`.

#### set a value in a given context

    apache_directive { 'StartServers for mpm_prefork_module':
      ensure      => present,
      name        => 'StartServers',
      context     => 'IfModule[arg="mpm_prefork_module"]',
      args        => 4,
    }


The directive is nested in the context of the `mpm_prefork_module` module, so we specify this with the `context` parameter.

The value of `StartServers` for the `mpm_prefork_module` module will be set/updated to `4`. Note that the `IfModule` entry will not be created if it is missing.

#### manage entry with composite namevars

    apache_directive { 'Options of Directory[arg=\'"/var/www/html"\']':
      ensure      => present,
      args        => ['FollowSymLinks', ],
    }

    apache_directive { 'Options of Directory[arg=\'"/var/www/icons"\']':
      ensure      => present,
      args        => ['MultiViews', 'FollowSymLinks', ],
    }


### apache_setenv provider

This is a custom type and provider supplied by `augeasproviders`.

#### manage simple entry

    apache_setenv { "SPECIAL_PATH":
      ensure => present,
      value  => "/foo/bin",
    }

#### manage entry with no value

    apache_setenv { "ENABLE_FOO":
      ensure  => present,
    }

#### delete entry

    apache_setenv { "SPECIAL_PATH":
      ensure => absent,
    }

#### manage entry in another config location

    apache_setenv { "SPECIAL_PATH":
      ensure => present,
      value  => "/foo/bin",
      target => "/etc/httpd/conf.d/app.conf",
    }


## Issues

Please file any issues or suggestions [on GitHub](https://github.com/hercules-team/augeasproviders_apache/issues).
