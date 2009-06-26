#!perl
use strict;
use Test::More;
use AnyEvent::IRC::Test;
use AnyEvent::IRC::Util qw/encode_ctcp prefix_nick/;

test_init (4, 1);

state (start => undef, undef, sub {
   $CL->dcc_initiate ($NICK2, 'CHAT', 0, "127.0.0.1", 9593);
}, 'bot1_registered', 'bot2_registered');

$CL->reg_cb (
   dcc_accepted => sub {
      my ($CL, $id, $type, $hdl) = @_;
      $CL->send_dcc_chat ($id, "TEST 1");
      ok (1, "received dcc accept");
   },
   dcc_chat_msg => sub {
      my ($CL, $id, $msg) = @_;
      if ($msg =~ /TEST REPL/) {
         ok (1, "received test msg reply");
         $CL->dcc_disconnect ($id);
      }
   },
   dcc_close => sub {
      my ($CL, $id, $type, $reason) = @_;
      $CL->disconnect ("done");
   }
);

$CL2->reg_cb (
   dcc_request => sub {
      my ($CL2, $id, $src, $type, $arg, $addr, $port) = @_;
      $CL2->dcc_accept ($id);
      ok (1, "received dcc request");
   },
   dcc_chat_msg => sub {
      my ($CL2, $id, $msg) = @_;
      my $i = 0;
      if ($msg =~ /TEST 1/) {
         $i = 1;
         $CL2->send_dcc_chat ($id, "TEST REPL");
      }

      ok (1, "received test msg");
   },
   dcc_close => sub {
      my ($CL2, $id, $type, $reason) = @_;
      $CL2->disconnect ("done");
   }
);

test_start;
