package AnyEvent::IRC::Test;
use strict;
no warnings;
require Exporter;
our @ISA = qw/Exporter/;
our @EXPORT = qw/test_init test_plan test_start $CL $CL2 $NICK $NICK2/;

use Test::More;
use AnyEvent;
use AnyEvent::IRC::Client;
use AnyEvent::IRC::Util qw/mk_msg/;

our $NICK;
our $NICK2;
our $CL;
our $CL2;
our $CV;
our $TMR;
our ($SERVER, $PORT) = (localhost => 6667);

=head1 NAME

AnyEvent::IRC::Test - A test helper module

=head1 SYNOPSIS

=head2 DESCRIPTION

=head2 METHODS

=over 4

=cut

sub test_init {
   my ($cnt, $nd_cl) = @_;

   if ($ENV{ANYEVENT_IRC_MAINTAINER_TEST_SERVER}) {
      if ($ENV{ANYEVENT_IRC_MAINTAINER_TEST_SERVER} =~ /^([^:]+)(?::(\d+))?$/) {
         ($SERVER, $PORT) = ($1, $2 || 6667);
      }
      plan tests => $cnt + 2 + 1 + ($nd_cl ? 2 : 0);
   } else {
      plan skip_all => "maintainer tests disabled, env var ANYEVENT_IRC_MAINTAINER_TEST_SERVER not set.";
      exit;
   }

   my $DEBUG = $ENV{ANYEVENT_IRC_MAINTAINER_TEST_DEBUG};

   my $cv_cnt = $nd_cl ? 2 : 1;
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
         $NICK = 'aicbot';
      },
      registered => sub {
         my ($con) = @_;
         $NICK = $con->nick;
      },
      disconnect => sub {
         my ($con, $reason) = @_;
         is ($reason, 'done', 'disconnect ok');
         $CV->broadcast if --$cv_cnt <= 0;
      }
   );

   if ($DEBUG) {
      $CL->reg_cb (
         debug_send => sub {
            my ($CL, $prefix, $command, @params) = @_;
            warn "1 SEND: ".mk_msg ($prefix, $command, @params);
         },
         debug_recv => sub {
            my ($CL, $msg) = @_;
            warn "1 RECV: ".mk_msg ($msg->{prefix}, $msg->{command}, @{$msg->{params}});
         }
      );
   }

   if ($nd_cl) {
      $CL2 = AnyEvent::IRC::Client->new;
      $CL2->reg_cb (
         connect => sub {
            my ($con, $err) = @_;
            if (defined $err) {
               fail ("second connection error: $err");
               $CV->broadcast;
               return;
            } else {
               pass ("second connection ok");
            }
            $con->register (qw/aicbot2 aicbot2 aicbot2/);
            $NICK2 = 'aicbot2';
         },
         registered => sub {
            my ($con) = @_;
            $NICK2 = $con->nick;
         },
         disconnect => sub {
            my ($con, $reason) = @_;
            is ($reason, 'done', 'disconnect ok');
            $CV->broadcast if --$cv_cnt <= 0;
         }
      );

      if ($DEBUG) {
         $CL2->reg_cb (
            debug_send => sub {
               my ($CL2, $prefix, $command, @params) = @_;
               warn "2 SEND: ".mk_msg ($prefix, $command, @params);
            },
            debug_recv => sub {
               my ($CL2, $msg) = @_;
               warn "2 RECV: ".mk_msg ($msg->{prefix}, $msg->{command}, @{$msg->{params}});
            }
         );
      }
   }
}

my $delay_timer;
sub test_start {
   my $delay = $ENV{ANYEVENT_IRC_MAINTAINER_TEST_DELAY};

   if ($delay) {
      $delay_timer = AnyEvent->timer (after => $delay, cb => sub {
         $CL->connect ($SERVER, $PORT);

         $delay_timer = AnyEvent->timer (after => $delay, cb => sub {
            $CL2->connect ($SERVER, $PORT)
         }) if defined $CL2;
      });
   } else {
      $CL->connect ($SERVER, $PORT);
      $CL2->connect ($SERVER, $PORT) if defined $CL2;
   }

   my $tout = 0;
   $TMR =
      AnyEvent->timer (
         after => 30 + $delay + ($CL2 ? $delay : 0),
         cb => sub { $tout = 1; $CV->broadcast }
      );
   $CV->wait;
   undef $TMR;
   ok (!$tout, "script didn't timeout");
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

