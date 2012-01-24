## A template for setting up a Datacouch


This is a refuge-based template for building Datacouches. 
It will give you:

 - a geocouch enabled Apache CouchDB 1.3 running on port 5914
 - preconfigured settings, proxies etc
 - all the node stuff running as daemons managed within
   the couch, logging to the couch logs, and shutting down when
   they fail too much too quickly, or when you shut down the couch.
 - a relative, moveable build with no hard paths
 - the datacouch app
 - a bunch of other apps

Don't use this live without disabling fakelogin (at a minimum).

Once you have Erlang and Node installed, clone and enter this 
repo, pick a username and password (these are for a new couch on port
5914, not any existing server), then:

`./build-datacouch.sh`

To start and stop the couch server and node servers, use `./start` and `./stop`.

Do something like what's on the last line of output of the build script above, 
about adding this line to your /etc/hosts: `127.0.0.1  datacouch.dev`, 
same for couchdb.dev. then open your browser to `http://datacouch.dev:5914`.
Create an app at http://dev.twitter.com for the oauth tokens to put into your
`datacouch.conf` file. To get started you can also log in to
http://datacouch.dev:5914/fakelogin without setting up the twitter credentials.

Requires:

 - [node](http://nodejs.org)
 - a recent [erlang](http://www.erlang.org/). 
   On Mac: `brew install erlang`
   Otherwise<sup>1</sup>


1: If this is not in the repos yet, it's easy to build 
(tested Ubuntu 11.04):
`curl -O http://www.erlang.org/download/otp_src_R15B.tar.gz
&& tar xvvzf otp_src_R15B.tar.gz`, enter directory, then `
./configure &&
make &&
sudo make install`

Rebar:

The build script sets up rebar in your user path if you don't
have it installed. If you want to install separately, clone or 
download rebar, then 

`cd rebar &&
./bootstrap &&
chmod +x rebar &&
cp rebar /usr/local/bin/rebar`

# Rebar templates for generating custom couchdb releases 

This project provides rebar templates that allows you to create your own
CouchDB releases or embed CouchDB applications based on the [rebared
version](https://github.com/refuge/rcouch) of Apache CouchDB provided by the [refuge
project](http://refuge.io). 

Platforms supported are Linux, FreeBSD 8.0x and sup, MacOSX 10.6/10.7
with Erlang R13B04/R14x, Windows is coming. Tested on i386, amd64 and
Arm platforms.

##Installation:

Install [rebar](https://github.com/basho/rebar). You can do that via
homebrew:

    $ brew update
    $ brew install rebar

Or build it from source

    $ git clone

*Note:* make sure to use the latest rebar version.

Drop these templates in ~/.rebar/templates.

    
##Create a custom CouchDB release

To create a custom release of CouchDB with your own plugins, use the
**rcouch** template:

    $ make myapp
    $ cd myapp
    $ rebar create template=rcouch appid=myapp


This prepares a custom rcouch release in the rel directory. You can
customize it by adding your plugins to rebar config and editing
rel/reltool.config. Then build and run it:

    $ make rel
    $ ./rel/myapp/bin/myapp

##Embed CouchDB in your application

To start an Erlang OTP application that embeds CouchDB, use the
**rebar_embed** template:

    $ rebar create template=rcouch_embed appid=myapp

It creates a custom app in apps/myapp/src that you can edit. Then use it
like above.

##Notes on building a truly distributable package

The package built above will still depend on some libraries from your
system, so additional work has to be done to distribute it to
older/newer systems.

1. CouchDB will depend on the ICU library version that was present in
   your system at build time. To easily bundle this library with the
   package, build with:

         $ make rel USE_STATIC_ICU=1

1. Check whether your package depends on Ncurses:

         $ ldd ./rel/myapp/erts-*/bin/erlexec|grep ncurses

    If it does, copy the .so file to ./rel/myapp/lib/ or rebuild Erlang
    without this dependency.

1. Decide whether you need SSL support in your package and check whether it
   depends on OpenSSL:

         $ ldd ./rel/myapp/lib/ssl-*/priv/bin/ssl_esock|grep 'libcrypto\|libssl'

    If it does, copy the .so file to ./rel/myapp/lib/ or rebuild Erlang
    without this dependency.

If you copied any .so files in the last 2 steps, run this command, so
that your app can find the libraries:

    $ sed -i '/^RUNNER_USER=/a\\nexport LD_LIBRARY_PATH="$RUNNER_BASE_DIR/lib"' ./rel/myapp/bin/myapp

