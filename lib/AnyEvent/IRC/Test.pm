package AnyEvent::IRC::Test;
use common::sense;
require Exporter;
our @ISA = qw/Exporter/;
our @EXPORT = qw/test_init test_plan test_start $CL $CL2 $NICK $NICK2 istate istate_check istate_done/;

use Test::More;
use AnyEvent;
use AnyEvent::IRC::Client;
use AnyEvent::IRC::Util qw/mk_msg encode_ctcp/;

our $NICK;
our $NICK2;
our $CL;
our $CL2;
our $CV;
our $TMR;
our %STATE;
our ($SERVER, $PORT) = (localhost => 6667);

=head1 NAME

AnyEvent::IRC::Test - A test helper module

=head1 SYNOPSIS

=head2 DESCRIPTION

=head2 METHODS

=over 4

=cut

sub read_env {
   my ($cnt, $nd_cl) = @_;

   if ($ENV{ANYEVENT_IRC_MAINTAINER_TEST_SERVER}) {
      if ($ENV{ANYEVENT_IRC_MAINTAINER_TEST_SERVER} =~ /^([^:]+)(?::(\d+))?$/) {
         ($SERVER, $PORT) = ($1, $2 || 6667);
      }
      if (defined $cnt) {
         plan tests => $cnt + 2 + 1 + ($nd_cl ? 2 : 0);
      }
   } else {
      plan skip_all => "maintainer tests disabled, env var ANYEVENT_IRC_MAINTAINER_TEST_SERVER not set.";
      exit;
   }
}

sub test_init {
   my ($cnt, $nd_cl) = @_;

   $NICK = 'aicbot';
   $NICK2 = 'AiCboT2';

   read_env ($cnt, $nd_cl);

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
      },
      error => sub {
         my ($con, $code, $message, $ircmsg) = @_;
         diag ("1 ERROR: $code: $message");
      },
      registered => sub {
         my ($con) = @_;
         $NICK = $con->nick;
         istate_done ('bot1_registered');
      },
      disconnect => sub {
         my ($con, $reason) = @_;
         is ($reason, 'done', 'disconnect ok');
         $CV->broadcast if --$cv_cnt <= 0;
      },
   );
   $CL->ctcp_auto_reply ('VERSION', ['VERSION', 'AnyEventTest:1.0:Perl']);

   if ($DEBUG) {
      $CL->reg_cb (
         debug_send => sub {
            my ($CL, $prefix, $command, @params) = @_;
            warn "1 SEND: " . mk_msg ($prefix, $command, @params) . "\n";
         },
         debug_recv => sub {
            my ($CL, $msg) = @_;
            warn "1 RECV: " . mk_msg ($msg->{prefix}, $msg->{command}, @{$msg->{params}}) . "\n";
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
         },
         error => sub {
            my ($con, $code, $message, $ircmsg) = @_;
            diag ("2 ERROR: $code: $message");
         },
         registered => sub {
            my ($con) = @_;
            $NICK2 = $con->nick;
            istate_done ('bot2_registered');
         },
         disconnect => sub {
            my ($con, $reason) = @_;
            is ($reason, 'done', 'disconnect ok');
            $CV->broadcast if --$cv_cnt <= 0;
         },
      );
      $CL2->ctcp_auto_reply ('VERSION', ['VERSION', 'AnyEventTest:1.0:Perl']);

      if ($DEBUG) {
         $CL2->reg_cb (
            debug_send => sub {
               my ($CL2, $prefix, $command, @params) = @_;
               warn "2 SEND: " . mk_msg ($prefix, $command, @params) . "\n";
            },
            debug_recv => sub {
               my ($CL2, $msg) = @_;
               warn "2 RECV: " . mk_msg ($msg->{prefix}, $msg->{command}, @{$msg->{params}}) . "\n";
            }
         );
      }
   }
}

my $delay_timer;
sub test_start {
   my $delay = $ENV{ANYEVENT_IRC_MAINTAINER_TEST_DELAY};

   if ($delay > 0) {
      $delay_timer = AnyEvent->timer (after => $delay, cb => sub {
         $CL->connect ($SERVER, $PORT, { nick => $NICK });

         $delay_timer = AnyEvent->timer (after => $delay, cb => sub {
            $CL2->connect ($SERVER, $PORT, { nick => $NICK2 })
         }) if defined $CL2;
      });
   } else {
      $CL->connect ($SERVER, $PORT, { nick => $NICK });
      $CL2->connect ($SERVER, $PORT, { nick => $NICK2 }) if defined $CL2;
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

sub istate {
   my ($state, $args, $cond, $cb, @prec) = @_;
   $STATE{$state} = { name => $state, args => $args, cond => $cond, cb => $cb, done => 0, prec => \@prec };

   istate_check ();
}

sub istate_done {
   my ($state) = @_;
   $STATE{$state} ||= {
      name => $state, args => undef, cond => undef, cb => undef, done => 0
   };
   $STATE{$state}->{done} = 1;

   istate_check ();
}

sub istate_check {
   my ($state, $cb) = @_;
   if (defined $state && $STATE{$state} && !$STATE{$state}->{done}) {
      $cb->($STATE{$state}->{args});
   }

   RESTART: {
      for my $s (grep { !$_->{done} } values %STATE) {
         if (@{$s->{prec} || []}
             && grep { !$STATE{$_} || !$STATE{$_}->{done} } @{$s->{prec} || []}) {
            next;
         }

         if (!defined ($s->{cond}) || $s->{cond}->($s->{args})) {
            if ($ENV{ANYEVENT_IRC_MAINTAINER_TEST_DEBUG}) {
               print "STATE '$s->{name}' OK\n";
            }
            $s->{cb}->($s->{args}) if defined $s->{cb};
            $s->{done} = 1;
            goto RESTART;
         }
      }
   }

   if ($ENV{ANYEVENT_IRC_MAINTAINER_TEST_DEBUG}) {
      warn "STATE STATUS:\n";
      for my $s (keys %STATE) {
         warn "\t$s => $STATE{$s}->{done}\t"
            . join (',', map {
                  "$_:$STATE{$s}->{args}->{$_}" } keys %{$STATE{$s}->{args}}
            )."\n";
      }
   }
}

=head1 AUTHOR

Robin Redeker, C<< <elmex@ta-sa.org> >>

=head1 SEE ALSO

=head1 COPYRIGHT & LICENSE

Copyright 2008-2009 Robin Redeker, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

