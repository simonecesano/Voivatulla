use strict;
use warnings;
use Data::Dump qw/dump/;

use FindBin;
# use DBI;
# use CHI;

use Plack::Builder;
use Plack::App::File;
use Plack::App::Proxy;

use Plack::Response;
# use Plack::Middleware::Cache::CHI;

use Mojo::Server::PSGI;

use lib './lib';
# use Mojo::Util qw(b64_decode url_escape url_unescape);
# use Mojo::JSON qw(decode_json encode_json);


$ENV{MOJO_SECRETS} = 'uno due tre';

my $config = {
	      apps => [
		       [qw/login.pl      u/],
		       [qw/voivattulla.pl a/],
		       [qw/lettera.pl/],
		       [qw/tree.pl/],
		       [qw/arewadare.pl  w/],
		      ],
	      login => '/u/v1',
	      error => '/e/v1',
	     };

builder {
    my @mounts = map { make_mount(@$_) } @{$config->{apps}};
    mount '/' => sub {
	my $req = Plack::Request->new(shift);
	my $res = Plack::Response->new(404);
	$res->content_type('text/html');
	$res->body("not found");
	return $res->finalize;
    };
};

sub make_app {
    my ($app, $mount, $version, $static);
    if (ref $_[0]) {
	($app, $mount, $version, $static) = @{$_[0]}{qw/app mount version static/}
    } else {
	($app, $mount, $version, $static) = @_;
    }

    $version ||= 1;
    $version =~ s/\D//g;
    $mount   ||= lc(substr($app, 0, 1));
    $mount   = '/' . $mount . '/v' . $version;
    
    $static  ||= $mount . '/static';
    return ($app, $mount, $version, $static)
}

sub make_mount {
    my ($app, $mount, $version, $static) = make_app(@_);

    mount $static => Plack::App::File->new(root => './public')->to_app;
    mount $mount => builder {
    	my $s = Mojo::Server::PSGI->new;
    	$s->load_app($app);
	unshift @{$s->app->renderer->paths}, ($s->app->renderer->paths->[0] . '/' . ($app =~ s/\.pl//r));
	# dump $s->app->renderer->paths;
	$s->app->hook(before_dispatch => sub {
			  my $c = shift;
			  unless (($c->session('user') && $c->session('password')) || ($mount eq $config->{login})) {
			      $c->session('referrer', $mount . '/' . $c->req->url->path);
			      $c->redirect_to($c->req->url->clone->path($config->{login})->to_abs);
			  } else {
			      $c->req->url->base->path($mount);
			  }
		      }
		     );
	$s->app->secrets([ split /\s+/, $ENV{MOJO_SECRETS} ]);
    	$s->to_psgi_app;
    };
    push @_, $mount;
    return \@_;
};
