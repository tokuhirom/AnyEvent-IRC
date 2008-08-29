#!perl
use strict;
use Test::More;
use AnyEvent::IRC::Test;

test_init (1);

$CL->reg_cb (
   test_end_of_motd => sub { # wait for end of MOTD
      my ($con) = @_;
      $con->send_srv (JOIN => '#aic_test_4');
   },
   ident_change => sub {
      my ($con, $nick, $ident) = @_;
      if ($con->is_my_nick ($nick)) {
         pass ("found my own ident");
         $con->disconnect ("done");
      }
   },
);

test_start;
