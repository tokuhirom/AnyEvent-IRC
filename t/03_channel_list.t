#!perl
use common::sense;
use Test::More;
use AnyEvent::IRC::Test;
use AnyEvent::IRC::Util qw/prefix_nick/;

test_init (11, 1);

istate (both_bots_joined => { },
   sub {
      ($CL->channel_list ('#aic_test_1') || {})->{$NICK}
      && ($CL->channel_list ('#aic_test_1') || {})->{$NICK2}
      && ($CL2->channel_list ('#aic_test_1') || {})->{$NICK}
      && ($CL2->channel_list ('#aic_test_1') || {})->{$NICK2}
   },
   sub {
      $CL->send_srv  (PRIVMSG => '#aic_test_1', "I'm 1");
      $CL2->send_srv (PRIVMSG => '#aic_test_1', "I'm 2");
   }
);

istate (both_bots_seen_each_other => { see_cnt => 2 },
   sub { $_[0]->{see_cnt} == 0 },
   sub {
      $CL->disconnect ('done');
      $CL2->disconnect ('done');
   },
   'both_bots_joined'
);

$CL->reg_cb (
   channel_add => sub { istate_check () },
   publicmsg => sub {
      my ($con, $targ, $msg) = @_;

      if ($targ eq '#aic_test_1') {
         is ($msg->{params}->[-1], "I'm 2", "message seen by first bot");
         is (prefix_nick ($msg), $NICK2, 'message for first bot came from second bot');

         my $chans = $con->channel_list;
         is ((join '', keys %$chans), '#aic_test_1', 'channel of first bot');

         ok (
            scalar (grep { $_ eq $NICK } keys %{$chans->{'#aic_test_1'}}),
            'first bot sees himself'
         );
         ok (
            scalar (grep { $_ eq $NICK2 } keys %{$chans->{'#aic_test_1'}}),
            'first bot sees second bot'
         );

         istate_check (both_bots_seen_each_other => sub { $_[0]->{see_cnt}-- });
      }
   }
);

$CL2->reg_cb (
   channel_add => sub { istate_check () },
   publicmsg => sub {
      my ($con, $targ, $msg) = @_;

      if ($targ eq '#aic_test_1') {
         is ($msg->{params}->[-1], "I'm 1", "message seen by second bot");
         is (prefix_nick ($msg), $NICK, 'message for first bot came from second bot');

         my $chans = $con->channel_list;
         is ((join '', keys %$chans), '#aic_test_1', 'channel of second bot');

         ok (
            scalar (grep {
               $con->nick_modes ('#aic_test_1', $_)->{o}
            } keys %{$chans->{'#aic_test_1'}}),
            'second bot sees that at least one has the mode "o"'
         );

         ok (
            scalar (grep { $_ eq $NICK } keys %{$chans->{'#aic_test_1'}}),
            'second bot sees first bot'
         );
         ok (
            scalar (grep { $_ eq $NICK2 } keys %{$chans->{'#aic_test_1'}}),
            'second bot sees himself'
         );

         istate_check (both_bots_seen_each_other => sub { $_[0]->{see_cnt}-- });
      }
   }
);

$CL->send_srv (JOIN => '#aic_test_1');
$CL2->send_srv (JOIN => '#aic_test_1');

test_start;
