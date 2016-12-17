#!/usr/bin/env perl

use Mojolicious::Lite;
use Yubin::UserAgent::EWS;
use Data::Dump qw/dump/;

get '/' => sub {
    my $c = shift;
    unless ($c->session('user') && $c->session('password')) {
	$c->render(template => 'login')
    } else {
	$c->render(template => 'landing')
    }
};

get '/login' => sub {
    my $c = shift;
    $c->render(template => 'login');
};

post '/login' => sub {
    my $c = shift;
    my $y = Yubin::UserAgent::EWS->new(user => $c->param('user'), password => $c->param('password'), endpoint => 'https://ews.adidas-group.com/ews/exchange.asmx');
    my $res = $y->request('resolve_name', { name => $c->param('user') });
    if ($res->is_success) {
	$c->session({ user => $c->param('user') });
	$c->session({ password => $c->param('password') });
	my $ref = $c->req->url->clone->path($c->param('referrer'))->to_abs;
	$c->redirect_to($ref || $c->url_for('/'));
    } else {
	$c->redirect_to($c->url_for('/error'));
    }	
};

get '/error' => sub {
    my $c = shift;
    $c->render(template => 'badlogin');
};

get '/logout' => sub {
    my $c = shift;
    $c->session({ password => undef });
    $c->session({ user => undef });
    $c->render(template => 'logout');
};

get '/timeout' => sub {
    my $c = shift;
    $c->session({ password => undef });
    $c->session({ user => undef });
    $c->render(template => 'timeout');
};

post '/keepalive' => sub { shift->render( text => 'alive for another 60 minutes!' ) };

app->start;

__DATA__

@@ login.html.ep
% layout 'default';
<div class="col-lg-12" style="min-height:12em"></div>
<div class="col-lg-4 col-xs-offset-4">
  <h1>Login</h1>
  <form method="post">
  <div class="form-group">
    <label for="user">User ID</label>
    <input type="text" class="form-control" id="user" name="user" placeholder="ID">
    <label for="password">Password</label>
    <input type="password" class="form-control" id="password" name="password" placeholder="password">
  </div>
  <button type="submit" class="btn btn-default">Login</button>
</form>
</div>

@@ logout.html.ep
% layout 'default';
<div class="col-lg-12" style="min-height:12em"></div>
<div class="col-lg-4 col-xs-offset-4">
  <h1>Goodbye!</h1><h2>and see you soon again!</h2>
</form>
</div>

@@ timeout.html.ep
% layout 'default';
<div class="col-lg-12" style="min-height:12em"></div>
<div class="col-lg-4 col-xs-offset-4">
  <h1>Your session has expired!</h1>
  <h3>it happens automatically after 60 minutes of no activity, for your own safety</h3>
  <h2>you can log back in <a href="/login">here</a></h2>
</div>

@@ badlogin.html.ep
% layout 'default';
<div class="col-lg-12" style="min-height:12em"></div>
<div class="col-lg-4 col-xs-offset-4">
  <h1>Sorry!</h1>
  <h2>bad user id or password</h2>
  <h2><a href="<%= url_for('/') %>">try again</a></h2>
</div>
