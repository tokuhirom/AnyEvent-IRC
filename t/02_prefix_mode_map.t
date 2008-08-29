#!perl
use strict;
use Test::More;
use AnyEvent::IRC::Test;

test_init (6);

is ($CL->map_prefix_to_mode ('@'), 'o', 'default op mode');
is ($CL->map_prefix_to_mode ('+'), 'v', 'default voice mode');
is ($CL->map_mode_to_prefix ('o'), '@', 'default reverse op mode');
is ($CL->map_mode_to_prefix ('v'), '+', 'default reverse voice mode');

$CL->reg_cb (
   test_end_of_motd => sub { # wait for end of MOTD
      my ($con) = @_;
      diag ("Available modes: " . (join ", ", $con->available_nick_modes));
      is ($con->map_prefix_to_mode ('@'), 'o', 'op mode');
      is ($con->map_mode_to_prefix ('o'), '@', 'reverse op mode');
      $con->disconnect ('done');
   }
);

test_start;
