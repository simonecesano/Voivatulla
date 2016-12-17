#!/usr/bin/env perl
use Mojolicious::Lite;

# Documentation browser under "/perldoc"
plugin 'PODRenderer';

get '/' => sub {
  my $c = shift;
  $c->render(template => 'mail');
};

post '/send' => sub {
    my $c = shift;
    app->log->info($c->param('html'));
    app->log->info($c->param('email'));
    my ($user, $pass) = ($c->session('user'), $c->session('password'));
    my $y = Yubin::UserAgent::EWS->new(user => $user, password => $pass, endpoint => 'https://ews.adidas-group.com/ews/exchange.asmx');
    my $res = $y->request('send_mail', { to => [ { email => $c->param('email') } ], body => $c->param('html'), subject => $c->param('subject') });
    $c->render(json => { xml => $res->xml })
};

any '/info' => sub {
    my $c = shift;
    my ($user, $pass) = ($c->session('user'), $c->session('password'));
    my $y = Yubin::UserAgent::EWS->new(user => $user, password => $pass, endpoint => 'https://ews.adidas-group.com/ews/exchange.asmx');
    app->log->info($c->param('email'));
    my $res = $y->request('resolve_name', { name => $c->param('email') });
    
    if ($c->param('f') =~ /xml/i) { $c->res->headers->content_type('text/xml'); return $c->render(text => $res->xml) }
    if ([ $res->xpath('//*/m:ResponseCode')->to_data ]->[0] =~ /ErrorNameResolutionNoResults/) { return $c->reply->exception('No results found') };
    
    my $email    = [ $res->xpath('//t:Resolution/*/t:EmailAddress')->to_data ]->[0];
    my $name     = [ $res->xpath('//t:Resolution/*/t:GivenName')->to_data ]->[0];
    my $surname  = [ $res->xpath('//t:Resolution/*/t:Surname')->to_data ]->[0];

    $c->render(json => { email => $email, name => $name, surname => $surname  } );
};

app->start;
__DATA__

@@ index.html.ep
% layout 'default';
% title 'Welcome';
<h1>Welcome to the Mojolicious real-time web framework!</h1>
To learn more, you can browse through the documentation
<%= link_to 'here' => '/perldoc' %>.
