package AnyEvent::IRC::Test;
use strict;
no warnings;
require Exporter;
our @ISA = qw/Exporter/;
our @EXPORT = qw/test_init test_start $CL/;

use Test::More;
use AnyEvent;
use AnyEvent::IRC::Client;

our $CL;
our $CV;
our ($SERVER, $PORT) = (localhost => 6667);

=head1 NAME

AnyEvent::IRC::Test - A test helper module

=head1 SYNOPSIS

=head2 DESCRIPTION

=head2 METHODS

=over 4

=cut

sub test_init {
   my ($test_cnt) = @_;

   if ($ENV{ANYEVENT_IRC_MAINTAINER_TEST_SERVER}) {
      if ($ENV{ANYEVENT_IRC_MAINTAINER_TEST_SERVER} =~ /^([^:]+)(?::(\d+))?$/) {
         ($SERVER, $PORT) = ($1, $2 || 6667);
      }

      plan tests => $test_cnt + 2;
   } else {
      plan skip_all => "maintainer tests disabled, env var ANYEVENT_IRC_MAINTAINER_TEST_SERVER not set.";
   }

   $CV = AnyEvent->condvar;
   $CL = AnyEvent::IRC::Client->new;
   $CL->reg_cb (
      connect => sub {
         my ($con, $err) = @_;
         if (defined $err) {
            fail ("connection error: $err");
            $CV->broadcast;
            return;
         } else {
            pass ("connection ok");
         }
         $con->register (qw/aicbot aicbot aicbot/);
      },
      disconnect => sub {
         my ($con, $reason) = @_;
         is ($reason, 'done', 'disconnect ok');
         $CV->broadcast;
      }
   );

}

sub test_start {
   $CL->connect ($SERVER, $PORT);
   $CV->wait;
}

=head1 AUTHOR

Robin Redeker, C<< <elmex@ta-sa.org> >>

=head1 SEE ALSO

=head1 COPYRIGHT & LICENSE

Copyright 2008 Robin Redeker, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

