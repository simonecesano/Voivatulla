package Yubin::UserAgent::EWS;

use Moose;
use JSON;

has [qw/xml/] => ( is => 'rw' );

with qw/Yubin::UserAgent::EWS::Requests 
	Yubin::UserAgent::EWS::LWP/;

use Want;
use XML::Bare qw/xmlin/;
use Yubin::UserAgent::EWS::Response;


sub request {
    my ($self, $template, $data) = @_;
    my $res = $self->post($self->compile($template, $data));
    return Yubin::UserAgent::EWS::Response->new({ response => $res });
}

__PACKAGE__->meta->make_immutable;

1;


1;
