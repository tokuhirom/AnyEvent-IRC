#!perl
use strict;
use Test::More;
use AnyEvent::IRC::Test;

test_init (6) or exit;

$CL->reg_cb (
   irc_376 => sub { # wait for end of MOTD
      my ($con) = @_;
      is ($con->map_prefix_to_mode ('@'), 'o', 'op mode ok');
      is ($con->map_prefix_to_mode ('+'), 'v', 'voice mode ok');
      is ($con->map_prefix_to_mode ('%'), 'h', 'half op mode ok');
      is ($con->map_mode_to_prefix ('o'), '@', 'reverse op mode ok');
      is ($con->map_mode_to_prefix ('v'), '+', 'reverse voice mode ok');
      is ($con->map_mode_to_prefix ('h'), '%', 'reverse half op mode ok');
      $con->disconnect ('done');
   }
);

test_start;
