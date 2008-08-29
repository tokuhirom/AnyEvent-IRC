#!perl
use strict;
use Test::More;
use AnyEvent::IRC::Test;
use AnyEvent::IRC::Util qw/prefix_nick/;
use JSON;

test_init (7, 1);

state (
   first_bot_joined => {},
   sub { ($CL->channel_list ('#aic_test_3') || {})->{$NICK} },
   sub {
      my $c = $CL->channel_list ('#aic_test_3');
      if ($c->{$NICK}->{o}) {
         pass ("first bot is op");
      } else {
         fail ("first bot is op");
         $CL->disconnect ("fail");
         $CL2->disconnect ("fail");
      }

      $CL2->send_srv (JOIN => '#aic_test_3');
   },
   'bot1_saw_motd', 'bot2_saw_motd'
);

state (
   second_bot_joined => {},
   sub { ($CL->channel_list ('#aic_test_3') || {})->{$NICK2} },
   sub {
      $CL->send_srv (MODE => '#aic_test_3' => '+v' => $NICK);
      $CL->send_srv (MODE => '#aic_test_3' => '+o' => $NICK2);
   },
   'first_bot_joined'
);

$CL->reg_cb (channel_add => sub { state_check; });

my $bot1_upd_cnt = 0;
my $bot2_upd_cnt = 0;
$CL2->reg_cb (
   channel_remove => sub {
      my ($con, $msg, $chan, @nicks) = @_;

      if (grep { $con->eq_str ($_, $NICK) } @nicks) {
         ok (!defined ($con->nick_modes ($chan, $NICK)), "nick modes of first bot reset after disconnect");
         $CL->disconnect ("done");
         $CL2->disconnect ("done");
      }
   },
   channel_nickmode_update => sub {
      my ($con, $chan, $nick) = @_;

      if ($con->eq_str ($NICK, $nick)) {
         my $modes = $con->nick_modes ($chan, $NICK);

         if ($bot1_upd_cnt == 0) {
            is ((join '', sort keys %$modes), 'o', 'first mode of first bot');

         } else {
            is ((join '', sort keys %$modes), 'ov', 'second mode of first bot');
         }

         $bot1_upd_cnt++;

      } elsif ($con->eq_str ($NICK2, $nick)) {
         my $modes = $con->nick_modes ($chan, $NICK2);

         if ($bot2_upd_cnt == 0) {
            is ((join '', sort keys %$modes), '', 'first mode of second bot');

         } elsif ($bot2_upd_cnt == 1) {
            is ((join '', sort keys %$modes), 'o', 'second mode of second bot');
            $con->send_srv (MODE => '#aic_test_3' => '+v' => $NICK2);

         } else {
            is ((join '', sort keys %$modes), 'ov', 'third mode of second bot');
            $CL->send_srv (PART => '#aic_test_3');
         }

         $bot2_upd_cnt++;
      }
   }
);

$CL->send_srv (JOIN => '#aic_test_3');

test_start;
