The `LogstashWriter` is an opinionated, reliable, and standards-observant
implementation of a means of getting events to a logstash cluster.


# Installation

It's a gem:

    gem install gemplate

There's also the wonders of [the Gemfile](http://bundler.io):

    gem 'gemplate'

If you're the sturdy type that likes to run from git:

    rake install

Or, if you've eschewed the convenience of Rubygems entirely, then you
presumably know what to do already.


# Logstash Configuration

In order for logstash to receive the events being written, it must have a
`json_lines` TCP input configured.  Something like this will do the trick:

    input {
      tcp {
        id    => "json_lines"
        port  => 5151
        codec => "json_lines"
      }
    }

We'd really like to support the more featureful lumberjack (or, these days,
"beats") protocol, but [Elastic refuses to document it
properly](https://github.com/elastic/libbeat/issues/279), so until such time
as that is fixed, we are stuck with the `json_lines` approach.


# Usage

An instance of `LogstashWriter` needs to be given the location of a server
(or servers) to send the events to.  This can be any of:

    # An IPv4 address and port
    lw = LogstashWriter.new(server_name: "192.0.2.42:5151")

    # An IPv6 address and port
    lw = LogstashWriter.new(server_name: "[2001:db8::42]:5151")
    # ... or without the brackets, if you like to live dangerously:
    lw = LogstashWriter.new(server_name: "2001:db8::42:5151")

    # A hostname that resolves to one or more A/AAAA addresses, and port
    lw = LogstashWriter.new(server_name: "logstash:5151")

    # A DNS name that resolves to one or more SRV records (which
    # specify the port as part of the record)
    lw = LogstashWriter.new(server_name: "_logstash._tcp")

Once you have your `LogstashWriter` instance, you can start firing
events:

    lw.send_event(any: "hash", you: "like")

However they won't actually be sent to the logstash server until you start
the background worker thread:

    lw.run

When it comes time to shutdown, you can do so gracefully, like this:

    lw.stop

This will wait for all events in the queue to drain to the logstash server
before returning.

In the event that a logstash server is unavailable at the time your events
are sent, events will be queued until a server is contactable.  However,
because memory is a finite resource, the backlog is limited to 1,000 events
by default.  If you want a larger (or smaller) limit, tell the writer when
you create it:

    lw = LogstashWriter.new(server_name: "...", backlog: 1_000_000)

If you want to know what your writer is doing, give it a logger:

    lw = LogstashWriter.new(server_name: "...", logger: Logger.new("/dev/stderr")


## Prometheus Metrics

If you're instrumentally inclined, you can get Prometheus metrics
out of the writer by passing a client registry (which you'll presumably know
what to do with if you're into that sort of thing):

    reg = Prometheus::Client::Registry.new
    lw = LogstashWriter.new(server_name: "...", metrics_registry: reg)

The metrics that are exposed are:

* **`logstash_writer_events_received_total`** -- the number of events that
  have been submitted for writing by calling `#send_event`.

* **`logstash_writer_events_written_total`** -- the number of events that
  have been submitted to the logstash server, labelled by `server` (the
  `address:port` pair for the server that each event was submitted to).

* **`logstash_writer_events_dropped_total`** -- the number of events
  that were dropped due to the backlog buffer filling up.  An increase
  in this value over time indicates that your logstash servers are either
  unreliable, or unable to cope with peak event ingestion loads.

* **`logstash_writer_queue_size`** -- the number of events currently in
  the backlog queue awaiting transmission.  In *theory*, this value should
  always be `received - (sent + dropped)`, but this gauge is maintained
  separately as a cross-check in case of bugs.

* **`logstash_writer_last_sent_event_timestamp`** -- the UTC timestamp,
  represented as the number of (fractional) seconds since the Unix epoch, at
  which the most recent event sent to a logstash server was originally
  submitted via `#send_event`.  This might require some unpacking.

  If everything is going along swimmingly, there's no queued events, and
  events submitted are immediately forwarded to logstash, this gauge will
  be whenever the last event was sent.  No big problem.  However, in the
  event of problems, this timestamp can tell you several things.

  Firstly, if there are queued events, you can tell how far behind in real
  time your logstash event history is, by calculating `NOW() -
  logstash_writer_last_sent_event_timestamp`.  Thus, if you're not finding
  events in your Kibana dashboard you were expecting to see, you can tell
  that there's a clog in the pipes by looking at this.

  Alternately, if the queue is empty, but this timestamp is perhaps older
  than you'd expect, then you know the problem is "upstream" of
  `LogstashWriter`.  If your code isn't calling `#send_event`, then this
  timestamp won't be progressing, and you can go look for a deadlock or
  something in your code, and don't need to check if logstash is misbehaving
  (again).

* **`logstash_writer_connected_to_server`** -- this flag timeseries (can be
  either `1` or `0`) is simply a way for you to quickly determine whether
  the writer has a server to talk to, if it wants one.  That is, this time
  series will only be `0` if there's an event to write but no logstash
  server can be found to write it to.

* **`logstash_writer_connect_exceptions_total`** -- a count of exceptions
  raised whilst attempting to connect to a logstash server, labelled by the
  exception class and the server to which the connection was attempted.

* **`logstash_writer_write_exceptions_total`** -- a count of exceptions
  raised whilst attempting to write data to a connected logstash server,
  labelled by the exception class and the server to which the write was
  directed.

* **`logstash_writer_write_loop_exceptions_total`** -- a count of exceptions
  raised in the "write loop", which is the main infinite loop executed by
  the background worker thread.  Exceptions which occur here are...
  concerning, because whilst exceptions are expected while connecting and
  writing to logstash servers, the write loop *itself* shouldn't normally
  be flinging exceptions around.

* **`logstash_writer_write_loop_ok`** -- a flag (can be either `1` or `0`)
  indicating whether the write loop is dead or not.  This is, essentially,
  the `up` series for the logstash writer; if this is `0`, nothing useful is
  happening in the logstash writer.


# Contributing

Patches can be sent as [a Github pull
request](https://github.com/discourse/logstash-writer).  This project is
intended to be a safe, welcoming space for collaboration, and contributors
are expected to adhere to the [Contributor Covenant code of
conduct](CODE_OF_CONDUCT.md).


# Licence

Unless otherwise stated, everything in this repo is covered by the following
copyright notice:

    Copyright (C) 2015  Civilized Discourse Construction Kit, Inc.

    This program is free software: you can redistribute it and/or modify it
    under the terms of the GNU General Public License version 3, as
    published by the Free Software Foundation.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
