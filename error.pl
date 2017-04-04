#!/usr/bin/env perl
use Mojolicious::Lite;

get '/' => sub {
  my $c = shift;
  $c->render(template => 'error');
};

app->start;
__DATA__

@@ error.html.ep
% title 'Error';
<h1>404</h1>
There was an error

