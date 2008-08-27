#!perl
use strict;
use Test::More;
use AnyEvent::IRC::Test;
use AnyEvent::IRC::Util qw/prefix_nick/;
use JSON;

test_init (11, 1);

$CL->reg_cb (
   publicmsg => sub {
      my ($con, $targ, $msg) = @_;

      if ($targ eq '#aic_test_1') {
         is ($msg->{params}->[-1], "I'm 2", "message seen by first bot");
         is (prefix_nick ($msg), 'aicbot2', 'message for first bot came from second bot');

         my $chans = $con->channel_list;
         is ((join '', keys %$chans), '#aic_test_1', 'channel of first bot');

         ok (
            scalar (grep { $_ eq 'aicbot' } keys %{$chans->{'#aic_test_1'}}),
            'first bot sees himself'
         );
         ok (
            scalar (grep { $_ eq 'aicbot2' } keys %{$chans->{'#aic_test_1'}}),
            'first bot sees second bot'
         );

         $con->disconnect ('done');
      }
   }
);

$CL2->reg_cb (
   publicmsg => sub {
      my ($con, $targ, $msg) = @_;

      if ($targ eq '#aic_test_1') {
         is ($msg->{params}->[-1], "I'm 1", "message seen by second bot");
         is (prefix_nick ($msg), 'aicbot', 'message for first bot came from second bot');

         my $chans = $con->channel_list;
         is ((join '', keys %$chans), '#aic_test_1', 'channel of second bot');

         ok (
            scalar (grep {
               $con->nick_modes ('#aic_test_1', $_)->{o}
            } keys %{$chans->{'#aic_test_1'}}),
            'second bot sees that at least one has the mode "o"'
         );

         ok (
            scalar (grep { $_ eq 'aicbot' } keys %{$chans->{'#aic_test_1'}}),
            'second bot sees first bot'
         );
         ok (
            scalar (grep { $_ eq 'aicbot2' } keys %{$chans->{'#aic_test_1'}}),
            'second bot sees himself'
         );

         $con->disconnect ('done');
      }
   }
);

$CL->send_srv (JOIN => '#aic_test_1');
$CL2->send_srv (JOIN => '#aic_test_1');
$CL->send_chan ('#aic_test_1', PRIVMSG => '#aic_test_1', "I'm 1");
$CL2->send_chan ('#aic_test_1', PRIVMSG => '#aic_test_1', "I'm 2");

test_start;
