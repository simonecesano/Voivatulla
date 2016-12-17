#!/usr/bin/env perl
use Mojolicious::Lite;
use Yubin::UserAgent::EWS;
use Data::Dump qw/dump/;

# Documentation browser under "/perldoc"
plugin 'PODRenderer';

use DateTime;
use CHI;

plugin 'CHI' => {
		 default => {
			     driver => 'Memory',
			     global => 1
			    }
		};

any '/r' => sub {
    my $c = shift;
    $c->render(template => 'hierarchy') unless $c->param('name');
    
    my ($user, $pass) = ($c->session('user'), $c->session('password'));
    my $y = Yubin::UserAgent::EWS->new(user => $user, password => $pass, endpoint => 'https://ews.adidas-group.com/ews/exchange.asmx');
    for ($c->param('f')) {
	/xml/ && do {
	    my $res = $y->request('get_manager', { name => $c->param('name') });
	    $c->res->headers->content_type('text/xml');
	    return $c->render(text => $res->xml)
	};
	/json/ && do {
	    if ((my $d = app->chi->get('hierarchy::name::' . $c->param('name'))) && 1) {
		app->log->info('cached ' .  $c->param('name'));
		return $c->render(json => $d )
	    } else {
		my $res = $y->request('get_manager', { name => $c->param('name') });
		my $h = {
			 reports => [ $res->xpath('//t:DirectReports/*/t:EmailAddress/..')->to_data ],
			 boss    => [ $res->xpath('//t:ManagerMailbox/*/t:EmailAddress/..')->to_data ]->[0],
			 name    => [ $res->xpath('//t:DisplayName')->to_data ]->[0],
			 title   => [ $res->xpath('//t:JobTitle')->to_data ]->[0],
			 dept    => [ $res->xpath('//t:Department')->to_data ]->[0],
			 mail    => [ $res->xpath('//t:Resolution/t:Mailbox')->to_data ]->[0],
			 # mobile  => [ $res->xpath('//t:Entry[@Key="MobilePhone"]/text()')->to_data ]->[0],
			};
		app->chi->set('hierarchy::name::' . $c->param('name'), $h);
		return $c->render(json => $h);
	    }
	};
    }
    $c->render(template => 'hierarchy')
};

get '/' => sub {
    my $c = shift;
    $c->redirect_to('/r');
};

any '/static/*file' => sub {
    my $c = shift;
    $c->reply->static($c->param('file'));
};


app->start;
__DATA__

@@ index.html.ep
% layout 'default';
% title 'Welcome';
<h1>Welcome to the Mojolicious real-time web framework!</h1>
To learn more, you can browse through the documentation
<%= link_to 'here' => '/perldoc' %>.

@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
  <head><title><%= title %></title></head>
  <body><%= content %></body>
</html>
