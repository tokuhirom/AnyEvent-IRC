package AnyEvent::IRC;
use strict;
use AnyEvent;
use IO::Socket::INET;

our $ConnectionClass = 'AnyEvent::IRC::Connection';

=head1 NAME

AnyEvent::IRC - An event system independend IRC protocol module

=head1 VERSION

Version 0.5

=cut

our $VERSION = '0.5';

=head1 SYNOPSIS

Using the simplistic L<AnyEvent::IRC::Connection>:

   use AnyEvent;
   use AnyEvent::IRC::Connection;

   my $c = AnyEvent->condvar;

   my $con = new AnyEvent::IRC::Connection;

   $con->connect ("localhost", 6667);

   $con->reg_cb (irc_001 => sub { print "$_[1]->{prefix} says i'm in the IRC: $_[1]->{trailing}!\n"; $c->broadcast; 0 });
   $con->send_msg (NICK => undef, "testbot");
   $con->send_msg (USER => 'testbot', "testbot", '*', '0');

   $c->wait;

Using the more sophisticatd L<AnyEvent::IRC::Client::Connection>:

   use AnyEvent;
   use AnyEvent::IRC::Client::Connection;

   my $c = AnyEvent->condvar;

   my $timer;
   my $con = new AnyEvent::IRC::Client::Connection;

   $con->reg_cb (registered => sub { print "I'm in!\n"; 0 });
   $con->reg_cb (disconnect => sub { print "I'm out!\n"; 0 });
   $con->reg_cb (
      sent => sub {
         if ($_[2] eq 'PRIVMSG') {
            print "Sent message!\n";
            $timer = AnyEvent->timer (after => 1, cb => sub { $c->broadcast });
         }
         1
      }
   );

   $con->send_srv (PRIVMSG => "Hello there i'm the cool AnyEvent::IRC test script!", 'elmex');

   $con->connect ("localhost", 6667);
   $con->register (qw/testbot testbot testbot/);

   $c->wait;
   undef $timer;

   $con->disconnect;

=head1 DESCRIPTION

The L<AnyEvent::IRC> module consists of L<AnyEvent::IRC::Connection>, L<AnyEvent::IRC::Client::Connection>
and L<AnyEvent::IRC::Util>. L<AnyEvent::IRC> only contains this documentation.
It manages connections and parses and constructs IRC messages.

L<AnyEvent::IRC> can be viewed as toolbox for handling IRC connections
and communications. It won't do everything for you, and you still
need to know a few details of the IRC protocol.

L<AnyEvent::IRC::Client::Connection> is a more highlevel IRC connection
that already processes some messages for you and will generated some
events that are maybe useful to you. It will also do PING replies for you
and manage channels a bit.

L<AnyEvent::IRC::Connection> is a lowlevel connection that only connects
to the server and will let you send and receive IRC messages.
L<AnyEvent::IRC::Connection> does not imply any client behaviour, you could also
use it to implement an IRC server.

Note that the *::Connection module uses AnyEvent as it's IO event subsystem.
You can integrate them into any application with a event system
that AnyEvent has support for (eg. L<Gtk2> or L<Event>).

=head1 EXAMPLES

See the samples/ directory for some examples on how to use AnyEvent::IRC.

=head1 AUTHOR

Robin Redeker, C<< <elmex@ta-sa.org> >>

=head1 SEE ALSO

L<AnyEvent::IRC::Util>

L<AnyEvent::IRC::Connection>

L<AnyEvent::IRC::Client::Connection>

L<AnyEvent>

RFC 1459 - Internet Relay Chat: Client Protocol
RFC 2812 - Internet Relay Chat: Client Protocol

=head1 BUGS

Please report any bugs or feature requests to
C<bug-net-irc3 at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=AnyEvent-IRC>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc AnyEvent::IRC

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/AnyEvent-IRC>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/AnyEvent-IRC>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=AnyEvent-IRC>

=item * Search CPAN

L<http://search.cpan.org/dist/AnyEvent-IRC>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to Marc Lehmann for the new AnyEvent module!

And these people have helped to work on L<AnyEvent::IRC>:

   * Maximilian Gaß - Added support for ISUPPORT and CASEMAPPING

=head1 COPYRIGHT & LICENSE

Copyright 2006 Robin Redeker, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
