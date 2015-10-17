Deployment system for servers and home directories.  In conjuction
with GNU Guix and (perhaps) the common workflow langauge (CWL)
essentially a replacement for Puppet, Chef, Cfengine, Cfruby, GNU
stow, etc.  See the doc/design.org document for more.

Historic note: at the time of Cfruby I decided that Cfruby was to be
one of my last `large' software projects.  How these things come to
haunt you! Cfruby is showing its age and now Deploy is bound to be a
large project, again.

Early days for deploy, YMMV.

Pjotr Prins (c) 2015

# Implementation (JIT)

Deploy is developed in JIT fashion. First steps are:

1. Get machine status (hostname, username, homedir) (done)
2. Read command file (done)
3. Implement mkdir (done)
4. Implement (recursive) file copy (done)
5. Implement (simple) file edit
6. Implement intermediate data format

Sorry, initially, no transactions, parallelization, fancy error
reporting etc. But it will come!  I have to start somewhere.  Call it
agility ;)

# License

This software is published under the MIT license.
