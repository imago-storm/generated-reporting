=head1 NAME

FlowPDF::Component::EF::Reporting::Metadata

=head1 AUTHOR

CloudBees

=head1 DESCRIPTION

A metadata object for FlowPDF::Component::EF::Reporting system.

=head1 METHODS


=head2 getValue()

=head3 Descripton

Returns decoded metadata value.

=head3 Parameters

=head3 Returns

=head3 Exceptions

=head3 Usage


=head2 getUniqueKey()

=head3 Descripton

Returns unique key for current metadata object.

=head3 Parameters

=head3 Returns

=head3 Exceptions

=head3 Usage



=head2 getReportObjectTypes()

=head3 Descripton

Returns report object types for current metadata object.

=head3 Parameters

=head3 Returns

=head3 Exceptions

=head3 Usage


=head2 getPropertyPath()

=head3 Descripton

Returns property path where metadata is stored or is to be stored.

=head3 Parameters

=head3 Returns

=head3 Exceptions

=head3 Usage



=cut

package FlowPDF::Component::EF::Reporting::Metadata;
use base qw/FlowPDF::BaseClass2/;
use FlowPDF::Types;

__PACKAGE__->defineClass({
    reportObjectTypes => FlowPDF::Types::ArrayrefOf(FlowPDF::Types::Scalar()),
    uniqueKey         => FlowPDF::Types::Scalar(),
    propertyPath      => FlowPDF::Types::Scalar(),
    value             => FlowPDF::Types::Reference('HASH'),
    pluginObject      => FlowPDF::Types::Any()
});

use strict;
use warnings;
use FlowPDF::Log;
use FlowPDF::Log::FW;

use JSON;
use Carp;


sub build {
    my ($class, $values) = @_;
}


sub newFromLocation {
    my ($class, $pluginObject, $location) = @_;

    fwLogDebug("Got metadata location: $location");
    my $ec = $pluginObject->getContext()->getEc();
    my $metadata = undef;

    my $retval = undef;
    eval {
        fwLogDebug("Retrieving metadata from $location");
        $metadata = $ec->getProperty($location)->findvalue('//value')->string_value();
        fwLogDebug("Retrieval result: $metadata");
        if ($metadata) {
            fwLogDebug("Metadata found: '$metadata', decoding...");
            $metadata = decode_json($metadata);
            fwLogDebug("Decoded metadata");
            $retval = __PACKAGE__->new({
                value        => $metadata,
                propertyPath => $location
            });
        }
        else {
            fwLogDebug("No metadata found at '$location'");
        }
    };

    logTrace("Returning created metadata");
    return $retval;
}


sub writeIt {
    my ($self) = @_;

    my $pluginObject = $self->getPluginObject();
    my $ec = $pluginObject->getContext()->getEc();
    my $location = $self->getPropertyPath();
    my $values = $self->getValue();
    $ec->setProperty($location => encode_json($values));
    return 1;
}
1;
