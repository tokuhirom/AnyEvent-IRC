#!perl
use utf8;
use common::sense;
use Test::More;
use AnyEvent::IRC::Test;
use AnyEvent::IRC::Util qw/split_prefix join_prefix/;
use Encode;

test_init (3);

my $cv = AE::cv;

my $msg = "きょきょなななにほんごなになほににぬまままま";
$msg = $msg x 13;
my $inmsg = '';

$CL->reg_cb (
   ident_change => sub {
      my ($con, $nick, $ident) = @_;

      if ($con->is_my_nick ($nick)) {
         ok (1, "found my own ident");

         $con->send_srv (NICK => 'tete123');
      }

      $con->unreg_me;
   },
   ctcp_action => sub {
      my ($con, $src, $targ, $m, $type) = @_;

      if ($con->is_my_nick ($targ)) {
         $inmsg .= decode ('utf-8', $m);

         if (length ($inmsg) == length ($msg)) {
            is ($inmsg, $msg, "complete message arrived");
            $con->disconnect ('done');
         }
      }
   },
   nick_change => sub {
      my ($con, $old, $new) = @_;

      my $oldid = $con->nick_ident ($old);

      my ($n, $u, $h) = split_prefix ($oldid);

      is ($con->nick_ident ($new), join_prefix ($new, $u, $h),
          "nick change detected correctly");

      $con->send_long_message (
         'utf-8', 0, "PRIVMSG\001ACTION", $con->nick, $msg);
   }
);

$CL->send_srv (JOIN => '#aic_test_4');

test_start;
