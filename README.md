# DEPLOY and SHEEPDOG

This is a simple 'declarative' deployment system for servers and home directories.  In conjuction with GNU Guix and (perhaps) GWL and the common workflow langauge (CWL) essentially a replacement for Puppet, Chef, Cfengine, Cfruby, GNU stow, etc.  See the doc/design.org document for more.

The tooling comes with the `sheepdog`: a minimalist monitor and notification system.
The purpose of `sheepdog' is to monitor problems in hardware and software on a larger setup.
Events, such as a succeeding or failing backup, get pushed onto a message queue for later digestion.
Sheepdog comes with its own webserver (in ./web/webserver.scm)

Important notice: much of the work on deploy has been arguably superceded by Guix and Guix home! As a matter of fact we use all.

=> https://guix.gnu.org/manual/devel/en/html_node/Home-Configuration.html

What remains of this effort is our faithful `sheepdog' to generate monitoring events and tools to process them.

Pjotr Prins (c) 2015-2024

## TODO

=> https://issues.genenetwork.org/search?query=sheepdog&type=all

# Sheepdog

Sheepdog is a tool for monitoring services. The idea is simple: use a
wrapper script to capture output of, for example, a backup run. On
error push a message out into a queue. The basic premises are:

- Only notify on FAIL (by default)
- Separation of concerns
- Make debugging of scripts easy

By default we use redis, but syslog and others may also be used.
The advantage of redis is that it is not bound to the same host, can cross firewalls using an ssh reverse tunnel (see below), and is easy to query.

    ./bin/sheepdog_run.rb -v -c 'echo "HELLO WORLD"'

To push a failing event

    ./bin/sheepdog_run.rb -v -c 'false'

To get the status, query with

    ./bin/sheepdog_list.rb
    2021-01-10 00:33:41 -0600 (penguin2) SUCCESS 0 <33m40s> TRIM
    2021-01-10 01:00:01 -0600 (penguin2) FAIL 1 <00m00s> CHK_BORG_GN2
    2021-01-10 01:00:01 -0600 (penguin2) SUCCESS 0 <00m00s> CHK_BORG_IPFS
    2021-01-10 01:00:01 -0600 (penguin2) SUCCESS 0 <00m00s> CHK_BORG_TUX01
    2021-01-10 01:00:01 -0600 (penguin2) SUCCESS 0 <00m00s> CHK_TUX01_MARIADB

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

Note that the message queue contains fields for the time stamp, the executed command and stdout/stderr. These are important for trouble shooting down the line.

Check jq out. It has a lot of powerful filters. To get the
last status of services do

    ./bin/sheepdog_list.rb --status|jq

Note that if redis fails to respond the commands will still run, but
(obviously) no event is recorded in redis.

We host a reference implementation here. Sheepdog has a number
of tricks:

## jq for filtered output

Reduce the number of fields:

    sheepdog_list.rb --status|jq '.[]| { time: .time, tag: .tag, status: .status }'

To see only the failing tags (-c outputs a record on a single line):

    sheepdog_list.rb --status|jq -c '.[]| select(.status=="FAIL") | { time: .time, tag: .tag, status: .status }'

```js
{"time":"2021-01-10 09:42:46 +0100","tag":"FETCH_P2","status":"FAIL"}
{"time":"2021-01-11 02:00:02 -0600","tag":"CHK_BORG_GN2","status":"FAIL"}
```

## Backups

An example for making a backup with the excellent borg tool, reporting
to a redis server running on a host named report.lan

```sh
#!/bin/bash

export stamp=$(date +%A-%Y%m%d-%H:%M:%S)
sheepdog_run.rb -c "borg create /export/backup/borg-etc::P2_etc-$stamp /etc" --tag 'P2-ETC' --log --always --host reporthost
```

and after running many backups it was time to create `sheepdog_borg'
which looks like

```sh
sheepdog_borg.rb -b /export/backup/borg-etc /etc
```

`sheepdog_borg` checks file permissions and will only run with a
passphrase set in $HOME/.borg-pass.  See the script for more info.
`sheepdog_borg` can be run as root. For security reasons, do not do
set that up as a CRON job (unless sheepdog and scripts are installed
by Guix into the immutable store).

## Find if a directory changed

When doing backups we want to know (1) whether a command ran,
(2) whether it failed and (3) assert something happened.

For the (3) Unix has

    find dir/ -iname "*" -mtime -2 -print

to see if anything changed in the last days. Sheepdog can do

    sheepdog_run.rb -v -c 'find . -iname "*" -mtime -2 -print|grep bin'

where `grep` generates a return value.

## Monitor a web service

This can easily be done with curl and grep:

    sheepdog_run.rb -c 'curl https://thebird.nl/|grep Pjotr'

## Monitor the monitor

Ok, you have a notification for your backup job. How do you know when
the server just stopped working? There are three things to add: a ping
or curl job to the machine (see above), and monitoring job output,
e.g. with above 'find if a directory changed'. In addition you can
monitor for failing redis PINGs by adding a daily ping to redis with

    sheepdog_ping.rb --host reporthost

and adding an 'expect' job to notify you if such a PING is not received
in time. Obviously one could run a ping every minute when reporting
is critical.


# Redis

Because we use redis we can use the following commands:

## Remove messages

```
redis-cli
KEYS sheepdog_*
DEL sheepdog_run
```

## Using passwords

When a server is configured with a password it can be passed on the
command line with `--password` or set in a file
`~/.config/sheepdog/sheepdog.conf`:

```js
{
  "redis": {
    "host"  : "localhost",
    "port" : 6379,
    "password": "123456"
  }
}
```

Note the password is the one used by redis and set in redis.conf with:

```
# comment out the bind command to listen to other interfaces and
requirepass 123456
```

Multiple hosts are supported in principle, but behaviour is (yet)
undefined. When you specify a host on the command line it will send a
message to that host using the password. Here, hostname will be the default
message queue and that can be overridden with the `--host` switch.

## Locking

We have a lock command which will check a lock file using the tag name.

sheepdog_rsync command has an option for using borg locks.

# Extra info

## Developing a new notification service

To create a new notification service it is easiest to go through
the following steps:

1. Create notification with `-v` and '`--always` flags
2. Run notification every minute (in CRON)
3. Use sheepdog_list to monitor the queue
4. Add `-v --full` and `--filter` options to view stdout/stderr
5. After making sure it works relax (1) and (2)

The notifications contain stdout and stderr output which should be
informative.

## E-mail failures

We can tell sheepdog to sent E-mails on failure. There are two scenarios:

1. E-mail directly - for critical services
2. E-mail daily digest - e.g., for backups

Receiving E-mails is very annoying, so when the sheepdog barks it
should be worth resolving.

To E-mail on failure simply use the `--email` switch:

```sh
sheepdog_rsync.rb --tag RSYNC_P2 genenetwork.org:/export/backup/tux01/* /export/backup/tux01/ --always --email admin@genenetwork.org -v --log --args '--delete'
```

## Typical CRON

This is what CRON jobs look like. To prevent injection, make sure the
scripts in a root CRON are only accessible by root!

```cron
GEM_PATH=/home/wrk/opt/deploy/lib/ruby/vendor_ruby
PATH=/home/wrk/iwrk/deploy/deploy/bin:/home/wrk/opt/deploy/bin:/bin:/usr/bin

# Once a week
0 0 * * 0 sheepdog_run.rb -c '/sbin/fstrim -a' --tag TRIM_P2 --host reporthost --log --always >> ~/cron.log 2>&1

22 4 * * 3 sheepdog_run.rb -c '/usr/bin/certbot renew --quiet' --tag CERTBOT_P2 --host reporthost >> ~/cron.log 2>&1

# Every day
0 0 * * * sheepdog_ping.rb --host reporthost

# Every 6 hours
0 0,6,12,18 * * * /export/backup/scripts/backup.sh  >> ~/cron.log 2>&1
```

Note that the redirection only for stuff not captured by sheepdog. It
is rare to look into those outputs. If you leave it out CRON may try
to send an E-mail on any output.

## REDIS reverse tunnel

Sometimes a redis queue is not directly reachable because it is inside a firewall. If the sheepdog machine can be reachead from the redis machine we can set up a reverse tunnel with ssh. That requires a password-less key and therefore we should give that user limited rights. On the machine running sheepdog create a user that has no shell access:

```
useradd redis-tun -m -s /bin/true
```

In /etc/ssh/sshd.conf set up

```
Match User redis-tun
  PermitOpen 127.0.0.1:6379
  X11Forwarding no
  AllowAgentForwarding no
  ForceCommand /bin/false
```

Generate a key as the user without a password

```
ssh-keygen -t ecdsa -f id_ecdsa_sheepdog
```

Now make sure the ssh key is on the redis host and

```
/usr/bin/ssh -i id_ecdsa_sheepdog redis-tun@sheepdoghost
/usr/bin/ssh -i id_ecdsa_sheepdog -f -N -L 6377:localhost:6379 redis-tun@sheepdoghost
```

Next you should be able to connect with

```
redis-cli -p 6377
```

And update sheepdog.conf accordingly

A CRON entry may look like

```
3 * * * * /usr/bin/ssh -i key -f -N -L 6377:localhost:6379 redis-tun@sheepdoghost >> tunnel.log &2>1
```

Note you can replace the -L swith with the -R switch to launche a *reverse* tunnel that would be initiatited from the other host.

# Check for connections

Sheepdog has an expect function to check for servers connecting. For example,
running the following on the queue

    sheepdog_expect.rb --filter penguin2 --elapse 3h

will add a FAIL event if penguin2 has not connected in the last three
hours, i.e. no messages where received in the queue.

# A webserver

Sheepdog comes with it own simple web server - see ./web/webserver.scm

# Install

To install dependencies:

    guix package -i ruby ruby-redis redis jq ruby-colorize borg -p ~/opt/deploy

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
