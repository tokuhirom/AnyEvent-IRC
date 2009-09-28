#!perl
use common::sense;
use Test::More;
use AnyEvent::IRC::Test;
use AnyEvent::IRC::Client;
use AnyEvent::IRC::Util qw/prefix_nick/;

AnyEvent::IRC::Test::read_env ();

my $err = AE::cv;
my $reg = AE::cv;
my $dis = AE::cv;

my $cl = AnyEvent::IRC::Client->new;

$cl->reg_cb (
   connect => sub {
      my ($cl, $e) = @_;

      if ($e) {
         $err->send ($e);
      }
   },
   registered => sub {
      $reg->send;
   },
   disconnect => sub {
      my ($cl, $reas) = @_;
      $dis->send ($reas);
   }
);

plan tests => 6;

my $delay = $ENV{ANYEVENT_IRC_MAINTAINER_TEST_DELAY};

for my $nr (1..3) {
   $err = AE::cv;
   $reg = AE::cv;
   $dis = AE::cv;

   $err->cb (my $fcb = sub {
      ok (0, "$nr connect: " . $_[0]->recv);
      exit;
   });
   $dis->cb ($fcb);

   my $del_cv = AE::cv;
   my $del_tmr = AE::timer $delay, 0, $del_cv;

   $del_cv->recv;

   $cl->connect (
      $AnyEvent::IRC::Test::SERVER,
      $AnyEvent::IRC::Test::PORT,
      { nick => "aeirct" });

   $reg->recv;

   ok (1, "$nr connect");

   $dis = AE::cv;

   $cl->send_srv (QUIT => 'done');

   ok (1, "$nr disconnect: " . $dis->recv);
}
