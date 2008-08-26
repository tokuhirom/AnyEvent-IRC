#!perl
use strict;
use Test::More;
use AnyEvent::IRC::Test;

test_init (10) or exit;

is ($CL->map_prefix_to_mode ('@'), 'o', 'default op mode');
is ($CL->map_prefix_to_mode ('+'), 'v', 'default voice mode');
is ($CL->map_mode_to_prefix ('o'), '@', 'default reverse op mode');
is ($CL->map_mode_to_prefix ('v'), '+', 'default reverse voice mode');

$CL->reg_cb (
   irc_376 => sub { # wait for end of MOTD
      my ($con) = @_;
      is ($con->map_prefix_to_mode ('@'), 'o', 'op mode');
      is ($con->map_prefix_to_mode ('+'), 'v', 'voice mode');
      is ($con->map_prefix_to_mode ('%'), 'h', 'half op mode');
      is ($con->map_mode_to_prefix ('o'), '@', 'reverse op mode');
      is ($con->map_mode_to_prefix ('v'), '+', 'reverse voice mode');
      is ($con->map_mode_to_prefix ('h'), '%', 'reverse half op mode');
      $con->disconnect ('done');
   }
);

test_start;
