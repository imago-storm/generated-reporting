=head1 NAME

FlowPDF::ContextFactory

=head1 AUTHOR

CloudBees

=head1 DESCRIPTION

A context factory that generates the L<FlowPDF::Context> object.

=head1 METHODS


=cut

package FlowPDF::ContextFactory;
use base qw/FlowPDF::BaseClass2/;
use FlowPDF::Types;

__PACKAGE__->defineClass({
    procedureName => FlowPDF::Types::Scalar(),
    stepName      => FlowPDF::Types::Scalar(),
});

use strict;
use warnings;
use Data::Dumper;
use FlowPDF::Context;
use ElectricCommander;


=over

=item B<newContext>

Creates new context object. Accepts as parameters a hashref with the following fields:

=over 4

=item B<procedureName>

Name of procedure where we are.

=item B<stepName>

Name of current step that is being executed.

=item B<pluginObject>

An L<FlowPDF> object or an object that inherits FlowPDF.

=item B<ec>

An ElectricCommander object.

This method should not be used directly without reason. ContextFactory has been designed to be used inside of L<FlowPDF> in a seamless way.

=back

=cut

sub newContext {
    my ($self, $ecpdf) = @_;

    my $context = FlowPDF::Context->new({
        procedureName => $self->getProcedureName(),
        stepName      => $self->getStepName(),
        pluginObject  => $ecpdf,
        ec            => ElectricCommander->new()
    });
    return $context;
}

=back

=cut

1;
