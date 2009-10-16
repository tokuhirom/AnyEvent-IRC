#!perl
use common::sense;
use Test::More;
use AnyEvent::IRC::Test;
use AnyEvent::IRC::Util qw/encode_ctcp prefix_nick/;

test_init (3);

istate (start => undef, undef, sub {
   is ($CL->away_status, undef, "not away on connect");
   $CL->send_srv (AWAY => "I'm not here");
}, 'bot1_registered');

$CL->reg_cb (
   away_status_change => sub {
      my ($CL, $status) = @_;

      if (defined $status) {
         ok ($CL->away_status, "got correct away status after changing");
         $CL->send_srv ('AWAY');

      } else {
         ok (!$CL->away_status, "got correct away status after unaway");
         $CL->disconnect ("done");
      }
   },
);

test_start;
