=pod

This app uses EWS to identify people. Doesn't do much else than provide a template and an api for identifying people

Should work like this:

-> post -> redirect to a page with names on table -> request all the names in parallel -> redo the table

Currently it kinda sucks: it breaks the back button

=cut

#!/usr/bin/env perl
use Mojolicious::Lite;
use Yubin::UserAgent::EWS;
use Data::Dump qw/dump/;


get '/' => sub {
    my $c = shift;
    my $q = $c->param('q');
    my ($user, $pass) = ($c->session('user'), $c->session('password'));
    if ($q) {
	my $y = Yubin::UserAgent::EWS->new(user => $user, password => $pass, endpoint => 'https://ews.adidas-group.com/ews/exchange.asmx');
	my $res = $y->request('resolve_name', { name => $q });
	if ($res->is_success && (1)) {
	    my @responses;
	    if ($res->xpath('//*/m:ResolveNamesResponseMessage/@ResponseClass') !~ /error/i) {
		@responses = $res->xpath('//*/t:Resolution')->to_data(sub { return shift })
	    } ;
	    $c->render(json => \@responses);
	} else {
	    $c->res->code(400);
	    $c->render(json => { error => 400, message => $res->response->message, xml => $res->xml });
	}	
    } else {
	$c->render(template => 'people')
    }
};

any '/static/*file' => sub {
    my $c = shift;
    $c->reply->static($c->param('file'));
};

app->start;
