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

We host a reference implementation here.

# License

This software is published under the MIT license.
