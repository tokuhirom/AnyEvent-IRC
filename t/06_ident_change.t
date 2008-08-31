#!perl
use strict;
use Test::More;
use AnyEvent::IRC::Test;

test_init (1);

$CL->reg_cb (
   ident_change => sub {
      my ($con, $nick, $ident) = @_;

      if ($con->is_my_nick ($nick)) {
         pass ("found my own ident");
         $con->disconnect ("done");
      }
   },
);

$CL->send_srv (JOIN => '#aic_test_4');

test_start;
