Deployment system for servers and home directories.  In conjuction
with GNU Guix and (perhaps) the common workflow langauge (CWL)
essentially a replacement for Puppet, Chef, Cfengine, Cfruby, GNU
stow, etc.  See the doc/design.org document for more.

Historic note: at the time of Cfruby I decided that Cfruby was to be
one of my last `large' software projects.  How these things come to
haunt you! Cfruby is showing its age and now Deploy is bound to be a
large project, again.

More information can be found in the
[design document](https://github.com/pjotrp/deploy/blob/master/doc/design.org).

Early days for deploy, YMMV.

Pjotr Prins (c) 2015-2021

# Implementation (JIT)

Deploy is developed in JIT fashion. First steps are:

1. Get machine status (hostname, username, homedir) (done)
2. Read command file (done)
3. Implement mkdir (done)
4. Implement (recursive) file copy (done)
5. Implement intermediate data 'bag' format (done)
6. Implement (simple) file edit (done)
7. Expand recursive file copy and file permissions (in progress)

Sorry, initially, no transactions, parallelization, fancy error
reporting etc. Use GNU Guix properly for doing deployment right! At
this stage I have started using deploy for machine management. Cfruby
is being phased out.

# Sheepdog

Sheepdog is a tool for monitoring services. The idea is simple: use a
wrapper script to capture output of, for example, a backup run. On
error push a message out into a queue. By default we use redis, but
syslog and others may also be used. The advantage of redis is that it
is not host bound and easy to query.

    ./bin/sheepdog_run.rb -v -c 'echo "HELLO WORLD"'

To get the status, query with

    ./bin/sheepdog_list.rb

And parse JSON with the great `jq` tool you can find [here](https://stedolan.github.io/jq/):

    ./bin/sheepdog_list.rb --json|jq

Outputs a nicely colored and formatted:

```js
{
    "time": "2021-01-09 16:00:34 +0000",
    "elapsed": 0,
    "host": "lario",
    "command": "find . -iname \"*\" -mtime -100 -print|grep binx",
    "tag": "HELLO",
    "stdout": "",
    "stderr": "",
    "status": 1,
    "err": "FAIL"
}
```

Check jq out. It has a lot of powerful filters. To get the
last status of services do

    ./bin/sheepdog_list.rb --status|jq

We host a reference implementation here. Sheepdog has a number
of tricks:

## Find if a directory changed

When doing backups we want to know (1) whether a command ran,
(2) whether it failed and (3) assert something happened.
For the (3) Unix has

    find dir/ -iname "*" -mtime -2 -print

to see if anything changed in the last days. Sheepdog can do

    sheepdog_run.rb -v -c 'find . -iname "*" -mtime -2 -print|grep bin'

where `grep` generates a return value.

# Install

To install dependencies:

    env GUIX_PACKAGE_PATH=~/iwrk/opensource/guix/guix-bioinformatics/ ~/.config/guix/current/bin/guix package -i ruby ruby-redis redis jq -p ~/opt/deploy

Setup the environment

    . ~/opt/deploy/etc/profile

(notice the leading dot) and run. Look inside profile to see the required
environment variables. The following may just do in CRON:

    GEM_PATH=$HOME/opt/deploy/lib/ruby/vendor_ruby

A (failing) CRON job may look like

    0 * * * * echo $HOME >> ~/sheepdog.log
    0 * * * * GEM_PATH=$HOME/opt/deploy/lib/ruby/vendor_ruby ~/iuser/deploy/deploy/bin/sheepdog_run.rb -c 'nono "HELLO WORLD"' --tag HELLO >> ~/sheepdog.log &2>1

GEM_PATH can also be set at the top of the crontab, but note that does no
variable expansion of $HOME. Something like this may work

    GEM_PATH=/home/user/opt/deploy/lib/ruby/vendor_ruby
    PATH=/home/user/iuser/deploy/deploy/bin:/home/user/opt/deploy/bin:/bin:/usr/bin

    0 * * * * sheepdog_run.rb -c 'echo "HELLO WORLD"' --tag HELLO -v >> ~/sheepdog.log

Do test with the -v switch and '>> log' to make sure your script works.
Thereafter

    GEM_PATH=/home/user/opt/deploy/lib/ruby/vendor_ruby
    PATH=/home/user/iuser/deploy/deploy/bin:/home/user/opt/deploy/bin:/bin:/usr/bin

    0 * * * * sheepdog_run.rb -c 'echo "HELLO WORLD"' --tag HELLO -v --log

should do the job.

# License

This software is published under the MIT license.
