=head1 NAME

FlowPDF::Component::EF::Reporting

=head1 AUTHOR

CloudBees

=head1 COMPONENT STATE

Current state of this component is late alpha version. Drop 1.

Currently, the state of this component allows you to implement CollectReportingData procedure for single payload-type per module.

However, multiple payload are designed, but not implemented yet. This will be a goal for the Drop 2.

=head1 DESCRIPTION

This module provides a component for Release Command Center (RCC) integration.

Before this component created, implementation of RCC integration was very complex and hard to setup.

This component provides a unified interface for RCC integrations using FlowPDF-Perl toolkit.

=head1 TERMINOLOGY

=over 4

=item Devops Insight Center

DevOps Insight provides dashboards that give you insights into deployment and release activities over time.

The ability to visualize this information as dashboards enables enterprises to understand the overall status of their processes,
identify hotspots that need action, understand trends, and find opportunities for further improvement.
DevOps Insight provides several dashboards as well as the ability to create custom dashboards.

These dashboards include the Release Command Center dashboard, which provides a centralized view of all activities and processes related to a release.

These include key metrics from the tools used across the end-to-end process, from work item tracking and build automation to test and operations tools.

The Release Command Center dashboard helps you to understand how many user stories are planned,
how many of them are "dev complete", how many are tested, what is the success rate of each of them, and other metrics that can help you better manage software production.

=item Release Command Center

Release Command Center is a part of Devops Insight Center and it shows a metrics that are gathered from different datasource of different types.

=item Data source

A system from where we're retrieving data for Devops Insight Center to shot them in Release Command Center.

It could be, basically, any kind of third-party software. For example, Jenkins, Jira, ServiceNow, SonarQube, etc.

=item Report Object Type

Each kind of report has it's own object type. Report object type defines a place where collected data will be shown.

For example, Jenkins datasource has report object type "build" for builds and "quality" for test reports.

JIRA has 'feature' for improvement tickets, and "defect" for bug issues. ServiceNow has an "incident" report object type.

=item Payload

Payload is a data that represents single entity for each report object type. For example, if we're collecting reporting data from jenkins

for HelloWorld project, we will have a payload object of a build type for each build that were already built.

So, if we have 10 builds, we should send 10 payloads.

Each payload of certain report object type has its own set of defined fields that should be sent.

We're building payloads from the data, that is being retrieved from data source.

=item Records set

Records set is a raw data that is retrieved from data source. It should be an array of hashes.

=item Data set

Data set is an array of hashes (dicts) that is created from records set. In that case it should be a flat array of a flat hashes.

So, each of hashes should have only a scalar values for its keys.

=item Payload set

Payload set is a set of payloads, that are already prepared to be sent to the reporting system.

=item Transform script

A script that is provided by user using procedure form or directly to be applied to each record in records set.

=item Metadata

An information that allows reporting system to know last reported object. It is being built from latest payload that was sent.

Metadata is being stored as JSON in the property. The address of these property is could be default or set by user.

Default place of property is depends on the context. For regular context it will be set to the current project.

In context of schedule it will be stored in the schedule properties.

=back

=head1 Data Flow

Datasource => Records Set => Transformed Records Set => Data Set => Payload Set

The key idea of reporting is:

=over 4

=item Read data from datasource (jira, jenkins, etc) about some metric (issues count, build status, etc).

=item Create a set of payloads from retrieved dataset.

=item Send it to EF instance.

=item Write a fingerprint (we call it metadata) of latest payload and store it somewhere.

=item On the next run, validate metadata to make sure that we need or need no of new reports.

=back

=head1 WHAT DO YOU NEED TO IMPLEMENT REPORTING?

To implement reporting you need to have the following things (if you have all of them, reporting implementation for your plugin is simple enough).

=over 4

=item An unique key/metric/value of each record/payload.

This value will be your keypoint of reporting. This value should be unique and you should have a way of comparison between two values, to get which is later.
For example, in Jenkins it is a build number. Build number is an unique value of each build inside a jenkins project.
Let's say, that we did a successful reporting of set of jenkins builds, and latest was 42. Then, someone triggering a new build, and latest build number is 43 now.
That is, we can easily compare 42 and 43 and understand, that if new build number is more than latest stored, we need to report.

=item An API that allows you to get latest record.

When it is possible to get a latest record by your criteria from datasource, you can

=back

=head1 How to implement reporting.

To get reporting one need to create a subclass of FlowPDF::Component::EF::Reporing within your project and implement following functions:

=over 4

=item compareMetadata($localMetadata, $latestRemoteMetadata);

A metadata comparator. It should work exactly as cmp, <=> or any other sort function.

If your metadata that is stored on EF side is pointing on non-latest data, simply return 1, it will trigger all logic.

Note: You don't have to create metadata object by yourself. This part is being handled by this component behind the scene.
For list of available methods of metadata object refer to: L<FlowPDF::Component::EF::Reporting::Metadata>.

=item initialGetRecords($pluginObject, $limit);

Function that is responsible for initial data retrieval. It will have as parameter $limit.
If limit is not passed or it is equals to 0, no limit is to be applied.

=item getRecordsAfter($pluginObject, $metadata);

A function that retrieves a newer records than a record that is stored on the EF side in metadata.

=item getLastRecord($pluginObject);

A function that always return a last record. This function should returh a hash reference instead of array of hash references.

=item buildDataset($pluginObject, $records);

A function that gets records set as parameter and builds a dataset from them.

Note, that transformation script is being applied right before this function automatically.

=item buildPayloadset($pluginObject, $dataset);

This function builds a payload set from dataset.

Note, that after this function validation of each payload will be performed, and if something is not correct, procedure will bail out.

=back

=head1 HOW TO IMPLEMENT REPORTING?

There are few steps to achieve that:

=over 4

=item Inherit this class.

%%%LANG=perl%%%

    package EC::Plugin::YourPlugin::Reporting;
    use base qw/FlowPDF::Component::EF::Reporting/;

%%%LANG%%%

=item Define a procedure for reporting (now manually, in the drop2 - using ecpdk).

=item Load component that you just created and define it:

%%%LANG=perl%%%

    my $reporting = FlowPDF::ComponentManager->loadComponent('EC::Plugin::YourPlugin::Reporting', {
        reportObjectTypes => ['build'],
        metadataUniqueKey => $params->{jobName},
        payloadKeys => ['buildNumber']
    }, $pluginObject);

%%%LANG%%%

Where:

=over 8

=item reportObjectTypes

An array reference of report object types that are supported by your component.

=item metadataUniqueKey

An unique key for metadata. It will be used to store metadata for different datasource entities in the different paths.

It should be set to some value. For example, if you have a parameter for the jenkins job, that should be reported, you may set this to it's value,
like HelloWorld. Basically, you can use any string here. But you need to be sure, that your unique key is really unique and you can use it for further
metadata retrieval. So, do not use any random values there.

=item payloadKeys

The fields of payload that will be used for metadata creation. An array reference of scalars. These fields should be present in payload.

If not, procedure will be failed. For example, if you have in payload buildNumber field, and you want to have this number as identifier, provide
just ['buildNumber'].

=back

=item Call CollectReportingData() from your component

%%%LANG=perl%%%

    $reporting->collectReportingData();

%%%LANG%%%

=back

=head1 EXAMPLE

This example demonstrates how it is possible to create CollectReportingData using this component manually.

%%%LANG=perl%%%

    package EC::Plugin::NewJenkins::Reporting;
    use Data::Dumper;
    use base qw/FlowPDF::Component::EF::Reporting/;
    use FlowPDF::Log;
    use strict;
    use warnings;

    sub compareMetadata {
        my ($self, $metadata1, $metadata2) = @_;
        my $value1 = $metadata1->getValue();
        my $value2 = $metadata2->getValue();
        # Implement here logic of metadata values comparison.
        # Return 1 if there are newer records than record to which metadata is pointing.
        return 1;
    }


    sub initialGetRecords {
        my ($self, $pluginObject, $limit) = @_;

        # build records and return them
        my $records = pluginObject->yourMethodTobuildTheRecords($limit);
        return $records;
    }


    sub getRecordsAfter {
        my ($self, $pluginObject, $metadata) = @_;

        # build records using metadata as start point using your functions
        my $records = pluginObject->yourMethodTobuildTheRecordsAfter($metadata);
        return $records;
    }

    sub getLastRecord {
        my ($self, $pluginObject) = @_;

        my $lastRecord = $pluginObject->yourMethodToGetLastRecord();
        return $lastRecord;
    }

    sub buildDataset {
        my ($self, $pluginObject, $records) = @_;

        my $dataset = $self->newDataset(['yourReportObjectType']);
        for my $row (@$records) {
            # now, data is a pointer, you need to populate it by yourself using it's methods.
            my $data = $dataset->newData({
                reportObjectType => 'yourReportObjectType',
            });
            for my $k (keys %$row) {
                $data->{values}->{$k} = $row->{$k};
            }
        }
        return $dataset;
    }

%%%LANG%%%

=head1 METHODS

=cut

package FlowPDF::Component::EF::Reporting;
use strict;
use warnings;
use base qw/FlowPDF::Component::EF/;
use FlowPDF::Types;

our $PREVIEW_MODE_ENABLED = 0;

__PACKAGE__->defineClass({
    metadataUniqueKey     => FlowPDF::Types::Scalar(),
    # an array reference of strings for report object types, like ['build', 'quality'];
    reportObjectTypes     => FlowPDF::Types::ArrayrefOf(FlowPDF::Types::Scalar()),
    initialRetrievalCount => FlowPDF::Types::Scalar(),
    pluginName            => FlowPDF::Types::Scalar(),
    pluginObject          => FlowPDF::Types::Any(),
    transformer           => FlowPDF::Types::Reference('FlowPDF::Component::EF::Reporting::Transformer'),
    payloadKeys           => FlowPDF::Types::ArrayrefOf(FlowPDF::Types::Scalar()),
});

use Data::Dumper;
use Carp;
use FlowPDF::Component::EF::Reporting::Dataset;
use FlowPDF::Component::EF::Reporting::Payloadset;
use FlowPDF::Component::EF::Reporting::Engine;
use FlowPDF::Helpers qw/bailOut/;
use FlowPDF::Log;
use FlowPDF::Log::FW;
use FlowPDF::Component::EF::Reporting::Metadata;
use FlowPDF::Component::EF::Reporting::MetadataFactory;
use FlowPDF::Component::EF::Reporting::Transformer;


sub init {
    my ($class, $pluginObject, $initParams) = @_;

    my $self = FlowPDF::Component::EF::Reporting->new();
    $self->setPluginName($pluginObject->getPluginName());

    if (!$initParams->{reportObjectTypes}) {
        bailOut("reportObjectTypes is mandatory");
    }

    if (!ref $initParams->{reportObjectTypes} || ref $initParams->{reportObjectTypes} ne 'ARRAY') {
        bailOut("ReportObjectTypes are expected to be an ARRAY reference.");
    }
    $self->setReportObjectTypes($initParams->{reportObjectTypes});
    if ($initParams->{initialRetrievalCount}) {
        $self->setInitialRetrievalCount($initParams->{initialRetrievalCount});
    }

    $self->setPluginObject($pluginObject);
    if ($initParams->{metadataUniqueKey}) {
        $self->setMetadataUniqueKey($initParams->{metadataUniqueKey});
    }
    if ($initParams->{payloadKeys}) {
        $self->setPayloadKeys($initParams->{payloadKeys});
    }
    # TODO: think about potential pitfalls of this.
    if ($class ne __PACKAGE__) {
        bless $self, $class;
    };

    my $runtimeParameters = $pluginObject->getContext()->getRuntimeParameters();

    if ($runtimeParameters->{transformScript}) {
        my $transformer = FlowPDF::Component::EF::Reporting::Transformer->new({
            pluginObject    => $pluginObject,
            transformScript => $runtimeParameters->{transformScript}
        });
        $transformer->load();
        $self->setTransformer($transformer);
    }

    if ($runtimeParameters->{previewMode}) {
        $PREVIEW_MODE_ENABLED = 1;
    }
    return $self;
}

sub isPreview {
    return $PREVIEW_MODE_ENABLED;
}

sub buildMetadataLocation {
    my ($self) = @_;

    my $po = $self->getPluginObject();
    my $context = $po->getContext();

    my $runtimeParameters = $context->getRuntimeParameters();
    if ($runtimeParameters->{metadataPropertyPath}) {
        logInfo("Metadata location was set in the procedure parameters to: $runtimeParameters->{metadataPropertyPath}\n");
        return $runtimeParameters->{metadataPropertyPath};
    }
    my $runContext = $context->getRunContext();
    my $projectName = $context->getCurrentProjectName();

    my $location = '';
    logInfo("Current run context is: '$runContext'");
    if ($runContext eq 'schedule') {
        my $scheduleName = $context->getCurrentScheduleName();
        $location = sprintf('/projects/%s/schedules/%s/ecreport_data_tracker', $projectName, $scheduleName);
    }
    else {
        $location = sprintf('/projects/%s/ecreport_data_tracker', $projectName);
    }

    logInfo "Built metadata location: $location";
    return $location;
}


=head2 CollectReportingData()

=head3 Description

Executes CollectReportingData logic and sends a reports to the Devops Insight Center.

=head3 Parameters

=over 4

=item None

=back

=head3 Returns

=over 4

=item None

=back

=head3 Exceptions

Throws a fatal error and exits with code 1 if something went wrong.

=head3 Usage

%%%LANG=perl%%%

    $reporting->CollectReportingData();

%%%LANG%%%

=cut

sub CollectReportingData {
    my ($self) = @_;

    my $metadataFactory = FlowPDF::Component::EF::Reporting::MetadataFactory->new({
        pluginObject      => $self->getPluginObject(),
        reportObjectTypes => $self->getReportObjectTypes(),
        propertyPath      => $self->buildMetadataLocation(),
        payloadKeys       => $self->getPayloadKeys(),
        uniqueKey         => $self->getMetadataUniqueKey()
    });
    $metadataFactory->setPropertyPath($metadataFactory->getPropertyPath . '/' . $metadataFactory->buildMetadataName());
    logInfo("Metadata Property Path: " . $metadataFactory->getPropertyPath());
    fwLogDebug("Reference inside of CollectReportingData: ", ref $self);
    my $pluginObject = $self->getPluginObject();
    my $stepResult = $pluginObject->getContext()->newStepResult();
    if (FlowPDF::Component::EF::Reporting->isPreview()) {
        $stepResult->setJobStepSummary("Preview mode is in effect. Without it you would have:");
    }
    my $runtimeParameters = $pluginObject->getContext()->getRuntimeParameters();
    if (!$runtimeParameters->{initialRetrievalCount}) {
        $runtimeParameters->{initialRetrievalCount} = 0;
    }
    # 1. Getting metadata from location.
    logDebug("Checking for metadata");
    my $metadata = $metadataFactory->newFromLocation();
    logDebug("Metadata from property: ", Dumper $metadata);
    if ($metadata) {
        logInfo("Metadata exists!");
        my $lastRecord = $self->getLastRecord($pluginObject);
        $lastRecord = [$lastRecord];
        my $transformer = $self->getTransformer();
        if ($transformer) {
            logInfo "Transformer is present.";
            for my $r (@$lastRecord) {
                $transformer->transform($r);
            }
        }
        my $dataset = $self->buildDataset($pluginObject, $lastRecord);
        my $payloadset;
        if ($self->can('buildPayloadset')) {
            $payloadset = $self->buildPayloadset($pluginObject, $dataset);
        }
        else {
            $payloadset = $self->defaultBuildPayloadset($pluginObject, $dataset);
        }
        my $lastMetadata = $metadataFactory->newMetadataFromPayload($payloadset->getLastPayload());
        # they are equal, return 1, reported data is actual;
        if ($self->compareMetadata($metadata, $lastMetadata) == 0) {
            logInfo("Up to date, nothing to sync.");
            $stepResult->setJobStepSummary("Up to date, nothing to sync");
            $stepResult->apply();
            return 1;
        }
    }

    my $records;
    if ($metadata) {
        $records = $self->getRecordsAfter($pluginObject, $metadata);
    }
    else {
        logDebug("No metadata, retrieving records");
        $records = $self->initialGetRecords($pluginObject, $runtimeParameters->{initialRecordsCount});
        logDebug("Records:", Dumper $records);
    }

    # now, we're applying transform script
    my $transformer = $self->getTransformer();
    if ($transformer) {
        logInfo "Transformer is present.";
        for my $r (@$records) {
            $transformer->transform($r);
        }
    }
    # end of transformation.

    # 2. get records after date, or all records, or with limit

    # 3. build dataset from records to be used as source for payloadset
    my $dataset = $self->buildDataset($pluginObject, $records);

    # 4. Create payloadset.
    # transform script will be applied to each payload object.
    my $payloads;
    if ($self->can('buildPayloadset')) {
        $payloads = $self->buildPayloadset($pluginObject, $dataset);
    }
    else {
        logDebug("buildPayloadSet function has not been defined, using defaultBuildPayloadset");
        $payloads = $self->defaultBuildPayloadset($pluginObject, $dataset);
    }
    $self->prepareAndValidatePayloads($payloads);

    # 5. finally report
    my $reportingResult = $payloads->report();
    logDebug("Reporting result: ", Dumper $reportingResult);
    $stepResult->setJobStepSummary("Payloads sent:");
    for my $reportType (keys %$reportingResult) {
        $stepResult->setJobStepSummary("Payloads of type $reportType sent: $reportingResult->{$reportType}");
    }
    $stepResult->apply();
    my $newMetadata = $metadataFactory->newMetadataFromPayload($payloads->getLastPayload());
    # 6. Write new metadata.
    if ($self->isPreview()) {
        logInfo("Preview mode is enabled, metadata is not going to be written");
    }
    else {
        $newMetadata->writeIt();
    }

    return 1;
}


sub defaultBuildPayloadset {
    my ($self, $pluginObject, $dataset) = @_;

    my $payloadSet = $self->newPayloadset($dataset->getReportObjectTypes());

    # my $payloads = $payloadSet->getPayloads();
    my $data = $dataset->getData();
    for my $row (@$data) {
        my $values = $row->getValues();
        my $pl = $payloadSet->newPayload({
            values => $values,
            reportObjectType => $row->getReportObjectType()
        });
        $self->convertDataToPayloadRecursive($pl, $row);
    }

    return $payloadSet;
}


sub convertDataToPayloadRecursive {
    my ($self, $payload, $data) = @_;

    my $dependentData = $data->getDependentData();
    for my $row (@$dependentData) {
        my $dependentPayload = $payload->createNewDependentPayload($row->getReportObjectType(), $row->getValues());
        $self->convertDataToPayloadRecursive($dependentPayload, $row);
    }
}


sub prepareAndValidatePayloads {
    my ($self, $payloadSet) = @_;

    if (ref $payloadSet ne 'FlowPDF::Component::EF::Reporting::Payloadset') {
        bailOut("PayloadSet are expected to be an FlowPDF::Component::EF::Reporting::Payloadset reference. Got: " . ref $payloadSet);
    }

    my $pluginObject = $self->getPluginObject();
    my $ec = $pluginObject->getContext()->getEc();
    my $reportingEngine = FlowPDF::Component::EF::Reporting::Engine->new({
        ec => $ec
    });

    my $preparedPayloads = $payloadSet->getPayloads();
    for my $row (@$preparedPayloads) {
        $self->prepareAndValidateSinglePayload($row, $reportingEngine);
    };
    return $self;
}


sub prepareAndValidateSinglePayload {
    my ($self, $payload, $reportingEngine) = @_;

    if (!ref $payload) {
        bailOut("prepareAndValidateSinglePayload: Expected a FlowPDF::Component::EF::Reporting::Payload reference for payload parameter.");
    }
    if (!ref $payload || ref $payload ne 'FlowPDF::Component::EF::Reporting::Payload') {
        bailOut("prepareAndValidateSinglePayload: Expected FlowPDF::Component::EF::Reporting::Payload, got:" . ref $payload);
    }
    # TODO: Prepare and validate top level of payload.

    # validating and converting payload
    logDebug "Payload BEFORE conversion: " . Dumper $payload;
    my $type = $payload->getReportObjectType();
    my $values = $payload->getValues();
    my $definition = $reportingEngine->getPayloadDefinition($type);
    for my $k (keys %$values) {
        if (!$definition->{$k}) {
            logWarning("$k that is present in payload is not present in $type object definition. Removing it from payload.");
            delete $values->{$k};
            next;
        }
        $values->{$k} = $self->validateAndConvertRow($k, $definition->{$k}->{type}, $values->{$k});
    }
    logDebug "Payload AFTER conversion: " . Dumper $payload->{values};

    # end of validation and conversion of payload
    my $dependentPayloads = $payload->getDependentPayloads();
    if (!@$dependentPayloads) {
        return $self;
    }

    for my $dp (@$dependentPayloads) {
        logInfo("Validating dependent payload...");
        $self->prepareAndValidateSinglePayload($dp, $reportingEngine);
    }
}


sub validateAndConvertRow {
    my ($self, $field, $type, $value) = @_;

    if ($type eq 'STRING') {
        return $value;
    }
    elsif ($type eq 'NUMBER') {
        # TODO: Improve validation here
        if ($value !~ m/^[0-9\-]+$/) {
            bailOut("Expected a number value, got: $value");
        }
        return $value +0;
    }
    elsif ($type eq 'DATETIME') {
        if ($value !~ /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,4})?Z$/) {
            bailOut "DATETIME field $field has incorrect value: $value. Expected value in Zulu timezone, like:YYYY-MM-DDTHH:MM:SS.sssZ\n";
        }
        return $value;
    }
    else {
        logInfo("Validation of field '$field' with type '$type' is not supported yet by FlowPDF-SDK.");
    }
    return $value;
}

=head2 newDataset($reportObjectTypes, $records);

=head3 Description

Creates a new L<FlowPDF::Component::EF::Reporting::Dataset> object from records set.

=head3 Parameters

=over 4

=item (Required)(ARRAY ref of scalars) A report object types to be used for dataset creation.

=item (Optional)(ARRAY ref or records) A list of L<FlowPDF::Component::EF::Reporting::Data> objects.

=back

=head3 Returns

=over 4

=item L<FlowPDF::Component::EF::Reporting::Dataset>

=back

=head3 Exceptions

Throws a missing parameters exception.

=head3 Usage

%%%LANG=perl%%%

    my $dataset = $reporting->newDataset(['build']);

%%%LANG%%%

=cut

sub newDataset {
    my ($self, $reportObjectTypes, $data) = @_;

    $data ||= [];
    if (!$reportObjectTypes) {
        croak "Missing reportObjectTypes for newDataset";
    }

    my $dataset = FlowPDF::Component::EF::Reporting::Dataset->new({
        reportObjectTypes => $reportObjectTypes,
        data              => $data
    });

    return $dataset;
};


=head2 newPayloadset($reportObjectTypes, $payloads);

=head3 Description

Creates a new L<FlowPDF::Component::EF::Reporting::Payloadset> object from records set.

=head3 Parameters

=over 4

=item (Required)(ARRAY ref of scalars) A report object types to be used for payload creation.

=item (Optional)(ARRAY ref or records) A list of L<FlowPDF::Component::EF::Reporting::Payload> objects.

=back

=head3 Returns

=over 4

=item L<FlowPDF::Component::EF::Reporting::Payloadset>

=back

=head3 Exceptions

Throws a missing parameters exception.

=head3 Usage

%%%LANG=perl%%%

    my $payloadset = $reporting->newPayloadset(['build']);

%%%LANG%%%

=cut

sub newPayloadset {
    my ($self, $reportObjectTypes, $payloads) = @_;

    $payloads ||= [];
    if (!$reportObjectTypes) {
        croak "Missing reportObjectTypes for newPayloadset";
    }

    my $pluginObject = $self->getPluginObject();
    my $ec = $pluginObject->getContext()->getEc();

    my $payloadset = FlowPDF::Component::EF::Reporting::Payloadset->new({
        reportObjectTypes => $reportObjectTypes,
        payloads          => $payloads,
        ec                => $ec,
    });

    return $payloadset;
}

# TODO: remove this later during cleanup of Drop1.
sub newMetadata {};

1;
