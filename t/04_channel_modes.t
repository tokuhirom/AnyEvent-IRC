#!perl
use strict;
use Test::More;
use AnyEvent::IRC::Test;
use AnyEvent::IRC::Util qw/prefix_nick/;
use JSON;

test_init (1, 1);

$CL->reg_cb (
   channel_usermode_update => sub {
      my ($con, $chan, $nick) = @_;

      if ($con->is_my_nick ($nick)) {
         if ($con->nick_modes ($chan, $con->nick)->{o}) {
            $con->send_srv (MODE => $chan => '+v' => $con->nick);
            $CL2->send_srv (JOIN => '#aic_test_2');
            
         } else {
            fail ("we got op on channel entry");
            $con->disconnect ("fail");
         }
      }
   }
);

$CL2->reg_cb (
   channel_usermode_update => sub {
      my ($con, $chan, $nick) = @_;

      if ($con->eq_str ('aicbot', $nick)) {
         my $modes = $con->nick_modes ($chan, 'aicbot');

         if ($con->isupport ('NAMESX')) {
            is ((join '', sort keys %$modes), 'ov', 'mode of first bot (namesx)');
         } else {
            is ((join '', sort keys %$modes), 'o', 'mode of first bot');
         }

         $CL->disconnect ("done");
         $CL2->disconnect ("done");
      }
   }
);

$CL->send_srv (JOIN => '#aic_test_2');

test_start;
