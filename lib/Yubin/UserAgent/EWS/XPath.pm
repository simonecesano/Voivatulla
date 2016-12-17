package Yubin::UserAgent::EWS::XPath;

use Moose::Role;

use XML::LibXML;
use XML::Bare qw/xmlin/;
use Data::Dump qw/dump/;

use Want;

has 'xpc' => ( is => 'ro', default => sub {
		  my $xpc = XML::LibXML::XPathContext->new;
		  $xpc->registerNs('t', 'http://schemas.microsoft.com/exchange/services/2006/types');
		  $xpc->registerNs('m', 'http://schemas.microsoft.com/exchange/services/2006/messages');
		  return $xpc;
	      } );

has nodelist => (
		 is => 'rw',
		 isa => 'XML::LibXML::NodeList'
		);

sub xpath {
    my ($self, $xpath, $xml) = @_;
    $xml ||= $self->xml;
    my $dom = XML::LibXML->load_xml(string => $xml);
    my $nodelist = $self->xpc->findnodes($xpath, $dom);
    $self->nodelist($nodelist);
    if (want('LIST')) {
	rreturn map { xmlin("$_") } $self->nodelist->get_nodelist;
    }
    elsif (want(qw'OBJECT')) {
	rreturn $self
    }
    return $self->nodelist;
}

sub to_data {
    my $self = shift;
    my $coderef = shift || sub { return shift };
    local $\ = "\n";
    if ($self->nodelist) {
	return map { xmlin("$_") } $self->nodelist->map($coderef)
    } else {
	return xmlin($self->xml);
    }

}

sub find {
    my ($self, $xpath, $xml) = @_;
    $xml ||= $self->xml;
    my $dom = XML::LibXML->load_xml(string => $xml);
    return ($self->xpc->find($xpath, $dom)->to_literal)
}

sub map {
}

1;
