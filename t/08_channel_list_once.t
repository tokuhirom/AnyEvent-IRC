#!perl
use strict;
use Test::More;
use AnyEvent::IRC::Test;
use AnyEvent::IRC::Util qw/prefix_nick/;
use JSON;

test_init (1);

my $join_cnt = 0;
my $t;

$CL->reg_cb (
   channel_add => sub {
      my ($con, $msg, $chan, @nicks) = @_;

      $t = AnyEvent->timer (after => 2, cb => sub { $con->disconnect ("done") });

      if (grep { $con->is_my_nick ($_) } @nicks) {
         $join_cnt++;
      }
   },
);

$CL->send_srv (JOIN => '#aic_test_1');

test_start;

is ($join_cnt, '1', "channel_add only called once for us");
