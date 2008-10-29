#!perl
use strict;
use Test::More;
use AnyEvent::IRC::Test;
use AnyEvent::IRC::Util qw/encode_ctcp/;

test_init (4, 1);

state (start => undef, undef, sub {
   $CL2->send_srv (PRIVMSG => $NICK, encode_ctcp (['VERSION']));
   $CL2->send_srv (PRIVMSG => $NICK, encode_ctcp (['PING', 1235]));
}, 'bot1_registered', 'bot2_registered');

state (done => undef, undef, sub {
   $CL->disconnect ("done");
   $CL2->disconnect ("done");
}, 'start', 'ctcp_version_reply', 'ctcp_ping_reply');

$CL->ctcp_auto_reply ('VERSION', ['VERSION', 'ScriptBla:0.1:Perl']);
$CL->ctcp_auto_reply ('PING', sub {
   my ($cl, $src, $target, $tag, $msg, $type) = @_;
   ['PING', $msg]
});

$CL2->reg_cb (
   ctcp_ping => sub {
      my ($CL2, $src, $target, $msg, $type) = @_;
      if ($src eq $NICK) {
         is ($type, 'NOTICE', 'ping ctcp type is NOTICE');
         is ($msg, '1235', 'ping ctcp contents is correct');
         state_done ('ctcp_ping_reply');
      }
   },
   ctcp_version => sub {
      my ($CL2, $src, $target, $msg, $type) = @_;
      if ($src eq $NICK) {
         is ($type, 'NOTICE', 'version ctcp type is NOTICE');
         is ($msg, 'ScriptBla:0.1:Perl', 'version ctcp contents is correct');
         state_done ('ctcp_version_reply');
      }
   },
);

test_start;
