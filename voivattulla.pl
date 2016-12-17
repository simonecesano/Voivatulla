#!/usr/bin/env perl

=pod

Voivatulla searches for free/busy status on EWS and shows the best slots for setting up a meeting  

Works like this:

-> post a request -> cache the params -> redirect to an md5 url -> get the params from the cache -> request freebusy statuses
    
=cut
    
use Mojolicious::Lite;
use Yubin::UserAgent::EWS;
use Data::Dump qw/dump/;
use Digest::MD5 qw(md5_hex);
use DateTime;
use CHI;

helper cache => sub {
    state $cache = CHI->new(
			    driver => 'File',
			    root_dir   => Path::Tiny->cwd->child('cache')->stringify,
			    cache_size => '2000k',
			    expires_in => 360,
			    on_set_error => sub { print STDERR join "\n", @_ }
			   );
    return $cache
};

post '/' => sub {
    my $c = shift;
    my $md5 = md5_hex($c->req->params->to_hash & time & rand(1000));
    my $hash = $c->req->params->to_hash;
    $hash->{names} = split /\s*,\s*|\s*;\s*|\n/, $hash->{names};
    app->cache->set($md5, $c->req->params->to_hash, "2 days");
    $c->redirect_to('/' . $md5);
};

get '/:md5' => [format => ['json'] ] => sub {
    my $c = shift;
    my $md5 = $c->param('md5');
    my $params = app->cache->get($md5);
    $params->{names} = [ split /;\s*|\r*\n/, $params->{names} ];
    $c->render(json => $params)
};

get '/:md5' => sub { shift->render(template => 'chart') };

#--------------------------------------
# this gets the freebusy status
#--------------------------------------

get '/' => sub {
    my $c = shift;
    if ($c->param('email')) {
	my ($user, $pass) = ($c->session('user'), $c->session('password'));
	my $y = Yubin::UserAgent::EWS->new(user => $user, password => $pass, endpoint => 'https://ews.adidas-group.com/ews/exchange.asmx');
	my $email = $c->param('email');
	my $start = $c->param('start') || DateTime->today()->iso8601() . 'Z';
	my $end   = $c->param('end')   || DateTime->today()->add(days => 70)->iso8601() . 'Z';

	app->log->info(dump $c->req->params->to_hash);
	app->log->info(dump $c->req->params->to_string);

	my $json;
	if (0) {
	# if (my $json = app->cache->get($c->req->params->to_string)) {
	    app->log->info('pulling from cache');
	    app->log->info(dump $json);
	    $c->render(json => $json);
	    return;
	} else {
	    my $res = $y->request('freebusy', { start => $start, end => $end, email => $email });
	    if ($c->param('xml')) {
		$c->res->headers->content_type('text/xml');
		$c->render(text => $res->xml)
	    } else {
		if ($res->is_success) {
		    my $d = $res->xpath('//*[local-name()=\'MergedFreeBusy\']');
		    app->log->info($d);
		    $c->render(json => { freebusy => $d, email => $email });
		} else {
		    $c->render(json => { error => 400, message => $res->response->message, xml => $res->xml });
		}
	    }
	}
    } else {
	unless ($c->session('user') || $c->session('password')) {
	    app->log->info($c->url_for('/login'));
	    $c->redirect_to('/login');
	} else {
	    $c->render(template => 'index')
	}
    }
};


any '/static/*file' => sub {
    my $c = shift;
    $c->reply->static($c->param('file'));
};

app->start;
