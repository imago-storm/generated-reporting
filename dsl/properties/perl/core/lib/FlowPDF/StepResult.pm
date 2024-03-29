=head1 NAME

FlowPDF::StepResult

=head1 AUTHOR

CloudBees

=head1 DESCRIPTION

This class sets various output results of step run in pipeline of procedure context.

=head1 METHODS

=cut

package FlowPDF::StepResult;

use base qw/FlowPDF::BaseClass2/;
use FlowPDF::Types;
__PACKAGE__->defineClass({
    context   => FlowPDF::Types::Reference('FlowPDF::Context'),
    actions   => FlowPDF::Types::ArrayrefOf(FlowPDF::Types::Reference('FlowPDF::StepResult::Action')),
    cache     => FlowPDF::Types::Reference('HASH'),
    isApplied => FlowPDF::Types::Enum(1, 0)
});

use strict;
use warnings;
use Carp;
use Data::Dumper;
use FlowPDF::StepResult::Action;
use FlowPDF::Log;
use FlowPDF::Log::FW;
use FlowPDF::EF::OutputParameters;
use FlowPDF::Helpers qw/inArray/;

sub getCacheForAction {
    my ($self, $actionType, $name) = @_;

    my $cache = $self->getCache();
    if ($cache->{$actionType} && $cache->{$actionType}->{$name}) {
        return $cache->{$actionType}->{$name};
    }
    return '';
}

sub setCacheForAction {
    my ($self, $actionType, $name, $value) = @_;

    fwLogDebug("Parameters for set cache: '$actionType', '$name', '$value'");
    my $cache = $self->getCache();
    my $line = $self->getCacheForAction($actionType, $name);
    if ($line) {
        $line = $line . "\n" . $value;
    }
    else {
        $line = $value;
    }
    $cache->{$actionType}->{$name} = $line;
    return $line;
}


=head2 setJobStepOutcome($jobStepOutcome)

=head3 Description

Schedules setting of a job step outcome. Could be warning, success or an error.

=head3 Parameters

=over 4

=item (Required)(String) desired procedure/task outcome. Could be one of: warning, success, error.

=back

=head3 Returns

=over 4

=item (FlowPDF::StepResult) self

=back

=head3 Usage

%%%LANG=perl%%%

    $stepResult->setJobStepOutcome('warning');

%%%LANG%%%

=cut

sub setJobStepOutcome {
    my ($self, $path, $outcome) = @_;

    if ($path && !$outcome) {
        $outcome = $path;
        $path = '/myJobStep/outcome';
    }
    if ($outcome !~ m/^(?:error|warning|success)$/s) {
        croak "Outcome is expected to be one of: error, warning, success. Got: $outcome\n";
    }
    my $action = FlowPDF::StepResult::Action->new({
        actionType  => 'setJobOutcome',
        entityName  => $path,
        entityValue => $outcome
    });

    my $actions = $self->getActions();
    push @$actions, $action;
    $self->setIsApplied(0);
    return $self;

}


=head2 setPipelineSummary($pipelineSummaryName, $pipelineSummaryText)

=head3 Description

Sets the summary of the current pipeline task.

Summaries of pipelien tasks are available on pipeline stage execution result under the "Summary" link.

Following code will set pipeline summary with name 'Procedure Exectuion Result:' to 'All tests are ok'

=head3 Parameters

=over

=item (Required)(String) Pipeline Summary Property Text

=item (Required)(String) Pipeline Summary Value.

=back

=head3 Returns

=over

=item (FlowPDF::StepResult) self

=back

=head3 Usage

%%%LANG=perl%%%

    $stepResult->setPipelineSummary('Procedure Execution Result:', 'All tests are ok');

%%%LANG%%%

=cut

sub setPipelineSummary {
    my ($self, $pipelineProperty, $pipelineSummary) = @_;

    if (!$pipelineProperty || !$pipelineSummary) {
        croak "pipelineProperty and pipelineSummary are mandatory.\n";
    }

    my $action = FlowPDF::StepResult::Action->new({
        actionType  => 'setPipelineSummary',
        entityName  => '/myPipelineStageRuntime/ec_summary/' . $pipelineProperty,
        entityValue => $pipelineSummary
    });

    my $actions = $self->getActions();
    push @$actions, $action;
    $self->setIsApplied(0);
    return $self;
}


=head2 setJobStepSummary($jobStepSummary)

=head3 Description

Sets the summary of the current B<job step>.

=head3 Parameters

=over 4

=item (Required)(String) Job Step Summary

=back

=head3 Returns

=over 4

=item (FlowPDF::StepResult) self

=back

=head3 Usage

%%%LANG=perl%%%

    $stepResult->setJobStepSummary('All tests are ok in this step.');

%%%LANG%%%

=cut

sub setJobStepSummary {
    my ($self, $summary) = @_;

    if (!$summary) {
        croak "Summary is mandatory in setJobStepSummary\n";
    }

    my $property = '/myJobStep/summary';
    my $action = FlowPDF::StepResult::Action->new({
        actionType => 'setJobStepSummary',
        entityName => $property,
        entityValue => $summary,
    });
    my $actions = $self->getActions();
    push @$actions, $action;
    $self->setIsApplied(0);
    return $self;
}


=head2 setJobSummary($jobSummary)

=head3 Description

Sets the summary of the current B<job>.

=head3 Parameters

=over 4

=item (Requried)(String) Job Summary

=back

=head3 Returns

=over 4

=item (FlowPDF::StepResult) self

=back

=head3 Usage

%%%LANG=perl%%%

    $stepResult->setJobSummary('All tests are ok');

%%%LANG%%%

=cut

sub setJobSummary {
    my ($self, $summary) = @_;

    if (!$summary) {
        croak "Summary is mandatory in setJobStepSummary\n";
    }

    my $property = '/myCall/summary';
    my $action = FlowPDF::StepResult::Action->new({
        actionType => 'setJobSummary',
        entityName => $property,
        entityValue => $summary
    });
    my $actions = $self->getActions();
    push @$actions, $action;
    $self->setIsApplied(0);
    return $self;
}

=head2 setOutcomeProperty($propertyPath, $propertyValue)

=head3 Description

Sets the outcome property.

=head3 Parameters

=over 4

=item (Required)(String) Property Path

=item (Required)(String) Value of property to be set

=back

=head3 Returns

=over

=item (FlowPDF::StepResult) self

=back

%%%LANG=perl%%%

    $stepResult->setOutcomeProperty('/myJob/buildNumber', '42');

%%%LANG%%%

=cut


sub setOutcomeProperty {
    my ($self, $propertyPath, $propertyValue) = @_;

    if (!defined $propertyPath || !defined $propertyValue) {
        croak "PropertyPath and PropertyValue are mandatory";
    }

    my $action = FlowPDF::StepResult::Action->new({
        actionType => 'setOutcomeProperty',
        entityName => $propertyPath,
        entityValue => $propertyValue
    });
    my $actions = $self->getActions();
    push @$actions, $action;
    $self->setIsApplied(0);
    return $self;
}


=head2 setOutputParameter($parameterName, $parameterValue)

=head3 Description

Sets an output parameter for a job.

=head3 Parameters

=over 4

=item (Required)(String) Output parameter name

=item (Required)(String) Output parameter value

=back

=head3 Returns

=over

=item (FlowPDF::StepResult) self

=back

%%%LANG=perl%%%

    $stepResult->setOutputParameter('Last Build Number', '42');

%%%LANG%%%

=cut

sub setOutputParameter {
    my ($self, $name, $value) = @_;

    if (!defined $name || !defined $value) {
        croak "Parameter name and parameter value are mandatory when set output parameter is scheduled";
    }

    my $action = FlowPDF::StepResult::Action->new({
        actionType => 'setOutputParameter',
        entityName => $name,
        entityValue => $value
    });
    my $actions = $self->getActions();
    push @$actions, $action;
    $self->setIsApplied(0);
    return $self;
}


=head2 setReportUrl($reportName, $reportUrl)

=head3 Description

Sets a report and it's URL for the job.
If it is being invoked in pipeline runs, sets also a property with a link to the pipeline summary.

=head3 Parameters

=over 4

=item (Required)(String) Report name

=item (Required)(String) Report URL

=back

=head3 Returns

=over

=item (FlowPDF::StepResult) self

=back

%%%LANG=perl%%%

    $stepResult->setReportUrl('Build Link #42', 'http://localhost:8080/job/HelloWorld/42');

%%%LANG%%%

=cut

sub setReportUrl {
    my ($self, $reportName, $reportUrl) = @_;

    if (!defined $reportName || !defined $reportUrl) {
        croak "Report name and report url are mandatory for setReportUrl.";
    }

    # if we have a pipeline run, we need to set an ec summary.
    if ($self->getContext()->getRunContext() eq 'pipeline') {
        my $summary = qq|<html><a href="$reportUrl" target="_blank">Download Report</a></html>|;
        $self->setPipelineSummary($reportName . ':', $summary);
    }

    $self->setOutcomeProperty(qq|/myJob/report-urls/$reportName|, $reportUrl);

    return $self;
}


sub newAction {
    my ($self, @params) = @_;

    my $action = FlowPDF::StepResult::Action->new(@params);
    my $actions = $self->getActions();
    push @$actions, $action;
    $self->setIsApplied(0);
    return $self;
}

=head2 apply()

=head3 Description

Applies scheduled changes without schedule cleanup in queue order: first scheduled, first executed.

=head3 Parameters

=over 4

=item None

=back

=head3 Returns

=over 4

=item (FlowPDF::StepResult) self

=back

%%%LANG=perl%%%

    $stepResult->apply();

%%%LANG%%%

=cut

sub apply {
    my ($self) = @_;

    $self->setIsApplied(1);
    my $actions = $self->getActions();
    for my $action (@$actions) {
        if (!ref $action) {
            croak "Reference is expected for action. Got scalar.";
        }
        if (ref $action ne 'FlowPDF::StepResult::Action') {
            croak "FlowPDF::StepResult::Action is expected. Got: ", ref $action;
        }

        my $currentAction = $action->getActionType();
        my $left = $action->getEntityName();
        my $right = $action->getEntityValue();
        my $ec = $self->getContext()->getEc();
        if ($currentAction eq 'setJobOutcome' || $currentAction eq 'setJobStepOutcome') {
            $ec->setProperty($left, $right);
        }
        # elsif ($currentAction eq 'setPipelineSummary' || $currentAction eq 'setOutcomeProperty' || $currentAction eq 'setJobSummary' || $currentAction eq 'setJobStepSummary') {
        elsif (inArray($currentAction, ('setPipelineSummary', 'setOutcomeProperty', 'setJobSummary', 'setJobStepSummary'))) {

            my $line;
            if ($currentAction ne 'setOutcomeProperty') {
                $line = $self->setCacheForAction($currentAction, $left, $right);
            }
            else {
                $line = $right;
            }
            fwLogDebug("Got line: $line\n");
            $ec->setProperty($left, $line);
        }
        elsif ($currentAction eq 'setOutputParameter') {
            my $op = FlowPDF::EF::OutputParameters->new({
                ec => $ec
            });
            $op->setOutputParameter($left, $right, {});
            # croak "Output parameters are not implemented yet for StepResult\n";
        }
        else {
            croak "Action $currentAction is not implemented yet\n";
        }
    }
    logTrace("Actions: ", Dumper $self->{actions});
    logTrace("Actions cache: ", Dumper $self->{cache});
    return $self;

}


=head2 flush()

=head3 Description

Flushes scheduled actions.

=head3 Parameters

=over 4

=item None

=back

=head3 Returns

=over 4

=item (FlowPDF::StepResult) self

=back

=head3 Usage

%%%LANG=perl%%%

    $stepResult->flush();

%%%LANG%%%

=cut

sub flush {
    my ($self) = @_;

    my $actions = $self->getActions();
    # now we're copying an actions array because it is a reference.
    my @clonedActions = @$actions;
    $self->setActions([]);
    $self->setCache({});

    return \@clonedActions;
}


=head2 applyAndFlush

=head3 Description

Executes the schedule queue and flushes it then.

=head3 Parameters

=over 4

=item None

=back

=head3 Returns

=over 4

=item (FlowPDF::StepResult) self

=back

=head3 Usage

%%%LANG=perl%%%

    $stepResult->applyAndFlush();

%%%LANG%%%

=cut

sub applyAndFlush {
    my ($self) = @_;

    $self->apply();
    return $self->flush();
}


sub applyIfNotApplied {
    my ($self) = @_;

    my $actions = $self->getActions();
    if (@$actions and !$self->getIsApplied()) {
        fwLogDebug("Executing auto-apply for FlowPDF::StepResult object.");
        return $self->apply();
    }
    return $self;
}
1;

