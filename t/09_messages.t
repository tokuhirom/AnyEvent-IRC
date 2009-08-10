#!perl
use common::sense;
use Test::More;
use AnyEvent::IRC::Test;
use AnyEvent::IRC::Util qw/encode_ctcp prefix_nick/;

test_init (4, 1);

state (start => undef, undef, sub {
   $CL->send_srv (PRIVMSG => $NICK2, "TEST");
   $CL->send_srv (PRIVMSG => $NICK2, "TEST 2");
   $CL2->send_srv (PRIVMSG => $NICK, "TEST");
   $CL2->send_srv (PRIVMSG => $NICK, "TEST 2");
}, 'bot1_registered', 'bot2_registered');

my @first_msgs;
my @second_msgs;

state (done => undef, sub { @first_msgs >= 2 && @second_msgs >= 2 }, sub {
   is ($first_msgs[0]->{params}->[-1], "TEST", "first message to first");
   is ($first_msgs[1]->{params}->[-1], "TEST 2", "second message to first");
   is ($second_msgs[0]->{params}->[-1], "TEST", "first message to second");
   is ($second_msgs[1]->{params}->[-1], "TEST 2", "second message to second");

   $CL->disconnect ("done");
   $CL2->disconnect ("done");
}, 'start');

$CL->reg_cb (
   privatemsg => sub {
      my ($CL, $nick, $privmsg) = @_;
      if ($CL->eq_str (prefix_nick ($privmsg), $NICK2)) {
         push @first_msgs, $privmsg;
      }
      state_check ();
   },
);

$CL2->reg_cb (
   privatemsg => sub {
      my ($CL, $nick, $privmsg) = @_;
      if ($CL->eq_str (prefix_nick ($privmsg), $NICK)) {
         push @second_msgs, $privmsg;
      }
      state_check ();
   },
);

test_start;
