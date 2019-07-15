package FlowPlugin::rep;
use strict;
use warnings;
use base qw/FlowPDF/;

use FlowPDF::Log;
# Feel free to use new libraries here, e.g. use File::Temp;

# Service function that is being used to set some metadata for a plugin.
sub pluginInfo {
    return {
        pluginName          => '@PLUGIN_KEY@',
        pluginVersion       => '@PLUGIN_VERSION@',
        configFields        => ['config'],
        configLocations     => ['ec_plugin_cfgs'],
        defaultConfigValues => {}
    };
}

## === step ends ===
# Please do not remove the marker above, it is used to place new procedures into this file.

# Procedure parameters:
# config
# featureParam
# param1
# reportObjectType
# previewMode
# transformScript
# debug
# releaseName
# releaseProjectName

sub collectReportingData {
    my $self = shift;
    my $params = shift;
    my $stepResult = shift;

    die 'Not implemented yet';

    
    # Multiple Payloads
    
    if ($params->{reportObjectType} eq 'feature') {
        my $featureReporting = FlowPDF::ComponentManager->loadComponent('FlowPlugin::rep::Reporting', {
            reportObjectTypes     => [ 'feature' ],
            metadataUniqueKey     => 'fill me in',
            payloadKeys           => [ 'fill me in' ]
        }, $self);
        $featureReporting->CollectReportingData();
    }
    
    if ($params->{reportObjectType} eq 'build') {
        my $buildReporting = FlowPDF::ComponentManager->loadComponent('FlowPlugin::rep::Reporting', {
            reportObjectTypes     => [ 'build' ],
            metadataUniqueKey     => 'fill me in',
            payloadKeys           => [ 'fill me in' ]
        }, $self);
        $buildReporting->CollectReportingData();
    }
    
    
}
sub validateCRDParams {
    my $self = shift;
    my $params = shift;
    my $stepResult = shift;

    # Add parameters check here, e.g.
    # if (!$params->{myField}) {
    #     use FlowPDF::Helpers qw/bailOut/;
    #     bailOut("Field myField is required");
    # }

    $stepResult->setJobSummary('success');
    $stepResult->setJobStepOutcome('Parameters check passed');

    exit 0;
}

## === feature step ends ===


1;