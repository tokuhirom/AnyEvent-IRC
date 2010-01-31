#!perl
use common::sense;
use Test::More;
use AnyEvent::IRC::Test;
use AnyEvent::IRC::Util qw/encode_ctcp prefix_nick/;

test_init (10, 1);

istate (start => undef, undef, sub {
   $CL->send_srv('KICK', '#aic_test_1', $NICK2, 'flooder');
}, 'bot1_registered', 'bot2_registered');

$CL->reg_cb (
   kick => sub {
      my ($CL, $kicked_nick, $channel, $is_myself, $msg, $kicker_nick) = @_;
      is($kicked_nick, $NICK2, "kicked_nick: $NICK2");
      is($channel, '#aic_test_1');
      ok($is_myself, 'is_myself');
      is($msg, 'flooder');
      is($kicker_nick, $NICK, "kicker_nick: $NICK");
      $CL->disconnect('done');
   },
);

$CL2->reg_cb (
   kick => sub {
      my ($CL2, $kicked_nick, $channel, $is_myself, $msg, $kicker_nick) = @_;
      is($kicked_nick, $NICK2, "kicked_nick: $NICK2");
      is($channel, '#aic_test_1');
      ok(!$is_myself, 'is_myself');
      is($msg, 'flooder');
      is($kicker_nick, $NICK, "kicker_nick: $NICK");
      $CL2->disconnect('done');
   },
);

$CL->send_srv (JOIN => '#aic_test_1');
$CL2->send_srv (JOIN => '#aic_test_1');

test_start;
