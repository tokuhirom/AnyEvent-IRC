package AnyEvent::IRC::Connection;
use strict;
no warnings;
use AnyEvent;
use POSIX;
use AnyEvent::Socket;
use AnyEvent::Handle;
use AnyEvent::IRC::Util qw/mk_msg parse_irc_msg/;
use Object::Event;

use base Object::Event::;

=head1 NAME

AnyEvent::IRC::Connection - An IRC connection abstraction

=head1 SYNOPSIS

   #...
   $con->send_msg (undef, "PRIVMSG", "Hello there!", "yournick");
   #...

=head1 DESCRIPTION

The connection class. Here the actual interesting stuff can be done,
such as sending and receiving IRC messages.

Please note that CTCP support is available through the functions
C<encode_ctcp> and C<decode_ctcp> provided by L<AnyEvent::IRC::Util>.

=head2 METHODS

=over 4

=item B<new>

This constructor does take no arguments.

=cut

sub new {
  my $this = shift;
  my $class = ref($this) || $this;

  my $self = { heap => {} };

  bless $self, $class;

  return $self;
}

=item B<connect ($host, $port)>

Tries to open a socket to the host C<$host> and the port C<$port>.
If an error occurred it will die (use eval to catch the exception).

=cut

sub connect {
   my ($self, $host, $port) = @_;

   $self->{socket}
      and return;

   tcp_connect $host, $port, sub {
      my ($fh) = @_;

      delete $self->{socket};

      unless ($fh) {
         $self->event (connect => $!);
         return;
      }

      $self->{host} = $host;
      $self->{port} = $port;

      $self->{socket} =
         AnyEvent::Handle->new (
            fh => $fh,
            on_eof => sub {
               $self->disconnect ("EOF from server $host:$port");
            },
            on_error => sub {
               $self->disconnect ("error in connection to server $host:$port: $!");
            },
            on_read => sub {
               my ($hdl) = @_;
               $hdl->push_read (line => sub {
                  $self->_feed_irc_data ($_[1]);
               });
            }
         );

      $self->event ('connect');
   };
}

=item B<disconnect ($reason)>

Unregisters the connection in the main AnyEvent::IRC object, closes
the sockets and send a 'disconnect' event with C<$reason> as argument.

=cut

sub disconnect {
   my ($self, $reason) = @_;
   return unless $self->{socket};
   delete $self->{socket};
   $self->event (disconnect => $reason);
}

=item B<is_connected>

Returns true when this connection is connected.
Otherwise false.

=cut

sub is_connected {
   my ($self) = @_;
   $self->{socket} && $self->{connected}
}

=item B<heap ()>

Returns a hash reference that is local to this connection object
that lets you store any information you want.

=cut

sub heap {
   my ($self) = @_;
   return $self->{heap};
}

=item B<send_raw ($ircline)>

This method sends C<$ircline> straight to the server without any
further processing done.

=cut

sub send_raw {
   my ($self, $ircline) = @_;
   $self->_send_raw ("$ircline\015\012");
}

sub _send_raw {
   my ($self, $data) = @_;

   unless ($self->{socket}) {
      die "Couldn't write to socket: Not connected!";
   }

   $self->{socket}->push_write ($data);
}

=item B<send_msg (@ircmsg)>

This function sends a message to the server. C<@ircmsg> is the argument list
for C<AnyEvent::IRC::Util::mk_msg>.

=cut

sub send_msg {
   my ($self, @msg) = @_;

   $self->event (sent => @msg);
   $self->_send_raw (mk_msg (@msg));
}

sub _feed_irc_data {
   my ($self, $line) = @_;

   my $m = parse_irc_msg ($line);

   $self->event (read => $m);
   $self->event ('irc_*' => $m);
   $self->event ('irc_' . (lc $m->{command}), $m);
}

=back

=head2 EVENTS

Following events are emitted by this module and shouldn't be emitted
from a module user call to C<event>. See also the documents L<Object::Event> about
registering event callbacks.

=over 4

=item B<connect>

This event is generated when the socket was successfully connected
or an error occurred while connecting. The error is given as second
argument to the callback then.

=item B<disconnect $reason>

This event will be generated if the connection is somehow terminated.
It will also be emitted when C<disconnect> is called.
The second argument to the callback is C<$reason>, a string that contains
a clue about why the connection terminated.

If you want to reestablish a connection, call C<connect> again.

=item B<sent @ircmsg>

Emitted when a message (C<@ircmsg>) was sent to the server.
C<@ircmsg> are the arguments to C<AnyEvent::IRC::Util::mk_msg>.

=item B<'*' $msg>

=item B<read $msg>

Emitted when a message (C<$msg>) was read from the server.
C<$msg> is the hash reference returned by C<AnyEvent::IRC::Util::parse_irc_msg>;

=back

=head1 AUTHOR

Robin Redeker, C<< <elmex@ta-sa.org> >>

=head1 SEE ALSO

L<AnyEvent::IRC>

L<AnyEvent::IRC::Client::Connection>

=head1 COPYRIGHT & LICENSE

Copyright 2006 Robin Redeker, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
