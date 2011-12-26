#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 28;
use Test::Mojo;
use File::Temp 'tempfile';
use File::Copy;
use Mojo::JSON;

use FindBin '$Bin';

# work on a temporary json file
my (undef, $tfn) = tempfile('urlicious_test_json_XXXX');
copy("$Bin/urls.json" => $tfn);

# create a tester for urlicious
$ENV{URLICIOUS_JSON_FILE} = $tfn;
require "$Bin/../urlicious";
my $t = Test::Mojo->new;

# redirect from existsing mojo file works
$t->get_ok('/mojo')->status_is(302);
is($t->tx->res->headers->location, 'http://mojolicio.us/', 'right redirect');

# form
$t->get_ok('/')->status_is(200);
$t->text_is(title => 'urlicious!');
$t->text_is('h1 a' => 'urlicious!');
$t->text_is('fieldset legend' => 'Get a smaller URL!');
$t->element_exists('form input[name=url]' => 'url field');
my $submit = $t->tx->res->dom->at('form')->attrs('action');
is($submit, $t->app->url_for('post'), 'right form url');

# post an url
my $long = 'http://netzverwaltung.info/echo.pl/WndlaSBNw7ZocmVuIGZsaWVnZW4gZHVyY2ggZGllIEx1ZnQuIFNhZ3QgZGllIGVpbmU6ICJTY2hh%0AdSBtYWwgZGEhIEVpbiBIdWJzY2hyYXAtc2NocmFwLXNjaHJhcC1zY2hyYXAtLi4uIg==%0A';
(my $long_short = $long) =~ s/^(.{42}).+$/$1.../;
$t->post_form_ok($submit, {url => $long})->status_is(200);
$t->text_is(p => 'Done. We created an alias for your URL:');
$t->text_is('tr:nth-child(1) th' => 'Your URL:');
$t->text_is("tr:nth-child(1) a[href=$long]" => $long_short);
$t->text_is('tr:nth-child(2) th' => 'The new alias:');
my $alias_url = $t->tx->res->dom->at('tr:nth-child(2) a')->attrs('href');
my $alias_rx  = qr|/([a-zA-Z0-9]{4})$|;
like($alias_url, $alias_rx, 'right alias format');
$t->text_is('tr:nth-child(2) a' => $alias_url);
$t->text_like('tr:nth-child(2) td' => qr/\(\d+% shorter\)/);

# got right redirect?
$t->get_ok($alias_url)->status_is(302);
is($t->tx->res->headers->location, $long, 'right redirect');

# json file updated?
open my $jfh, '<', $tfn or die "couldn't open $tfn: $!";
my %urls = %{Mojo::JSON->new->decode(join '' => <$jfh>)};
my $alias = $1 if $alias_url =~ $alias_rx;
ok(exists $urls{$alias}, 'json file updated');
is($urls{$alias}, $long, 'json file updated right');

# post an existing url again
$t->post_form_ok($submit, {url => $long})->status_is(200);
$t->text_is('tr:nth-child(2) a' => $alias_url);

# cleanup
unlink $tfn;
ok(!-e $tfn, 'temporary test json file deleted');

__END__
