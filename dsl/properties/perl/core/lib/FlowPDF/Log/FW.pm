=head1 NAME

FlowPDF::Log::FW

=head1 AUTHOR

CloudBees

=head1 NOTE

This module is not intented to be used by plugin developers. This module should be used only by FlowPDF developers.

=head1 DESCRIPTION

This module provides a log for the FlowPDF itself and should be imported and used only in FlowPDF libraries.

B<This module should not be used as logger for business-logic code. This is logger for framework itself.>

The logger that you're looking for is L<FlowPDF::Log>.

Also, please, note, that FlowPDF::Log::FW is a singleton. This object is automatically created during module import.

Just write:

%%%LANG=perl%%%

use FlowPWDF::Log::FW;

%%%LANG%%%

And now you have an already created and available logger.

=head1 SPECIAL ENVIRONMENT VARIABLES AND METHODS

This module reacts on the following environment variables:

=over 4

=item FLOWPDF_FW_LOG_TO_FILE

An absolute of wile where log will be written. If file could not be written, logging to the file will be disabled automatically
and warning will be shown in the logs.

=item FLOWPDF_FW_LOG_TO_PROPERTY

A property path where log will be written.

=item FLOWPDF_FW_LOG_LEVEL

A log level of logger. One of:

=over 8

=item 0 - INFO

=item 1 - DEBUG

=item 2 - TRACE

=back

Default is INFO.

=back

And following methods:

=over 4

=item setLogLevel();

=item getLogLevel();

=item setLogToProperty();

=item getLogProperty();

=item setLogToFile();

=item getLogFile();

=back

Please, note, that these logfile writing methods are not exclusive. It means that logger will write to all destination that are available.

For example, if log to property is enabled alongside with logging to file, log will be written to the property and to the file.

=head1 LOGGING METHODS

=over

=item fwLogInfo

=item fwLogDebug

=item fwLogTrace

=item fwLogError

=item fwLogWarning

=back

=cut

package FlowPDF::Log::FW;
use base qw/Exporter/;

our @EXPORT = qw/fwLogInfo fwLogDebug fwLogTrace fwLogError fwLogWarning/;
use strict;
use warnings;
use Data::Dumper;
use Carp;
use FlowPDF::Helpers qw/inArray/;

our $LOG_LEVEL = 0;
# file or property or empty.
our $LOG_TO_PROPERTY;
our $LOG_TO_FILE;

our $MASK_PATTERNS = [];
our $LOGGER = undef;

sub import {
    # this handler sets required log levels from different sources.
    # this logger has setup for two different aspects. 1: log level 2: log direction.
    # log level is a digit from -1 to 2, log direction is a string: file:/path/to/file or property:/path/to/property
    if ($ENV{FLOWPDF_FW_LOG_TO_FILE}) {
        $LOG_TO_FILE = $ENV{FLOWPDF_FW_LOG_TO_FILE};
    }
    if ($ENV{FLOWPDF_FW_LOG_TO_PROPERTY}) {
        $LOG_TO_PROPERTY = $ENV{FLOWPDF_FW_LOG_TO_PROPERTY};
    }
    if ($ENV{FLOWPDF_FW_LOG_LEVEL}) {
        $LOG_LEVEL = $ENV{FLOWPDF_FW_LOG_LEVEL};
    }
    else {
        $LOG_LEVEL = 0;
    }
    if (!$LOGGER) {
        $LOGGER = __PACKAGE__->new();
    }
    fwLogDebug("Debug level for framework is set to $LOG_LEVEL.");
    __PACKAGE__->export_to_level(1, @_);
};

use constant {
    ERROR => -1,
    INFO  => 0,
    DEBUG => 1,
    TRACE => 2,
};

sub getLoggerInstance {
    return $LOGGER;
}
sub parseLogDestination {
    my ($destination) = @_;

    my ($type, $location) = @_;

    if ($destination =~ m/^(.*?):(.*?)$/s) {
        $type = $1;
        $location = $2;
    }

    if (!$type || !$location) {
        return undef;
    }

    if ($type !~ m/^(?:file|property)$/s) {
        fwLogWarning("Destination is wrong. Currently only 'file' and 'property' are supported");
        return undef;
    }
    return ($type, $location) if wantarray();
    return [$type, $location];
}

sub setMaskPatterns {
    my (@params) = @_;

    unless (@params) {
        croak "Missing mask patterns for setMastPatterns.";
    }
    if ($params[0] eq __PACKAGE__ || ref $params[0] eq __PACKAGE__) {
        shift @params;
    }
    for my $p (@params) {
        next if isCommonPassword($p);
        $p = quotemeta($p);
        # avoiding duplicates
        if (inArray($p, @$MASK_PATTERNS)) {
            next;
        }

        push @$MASK_PATTERNS, $p;
    }
    return 1;
}

sub isCommonPassword {
    my ($password) = @_;

    # well, huh.
    if ($password eq 'password') {
        return 1;
    }
    if ($password =~ m/^(?:TEST)+$/is) {
        return 1;
    }
    return 0;
}

sub maskLine {
    my ($self, $line) = @_;

    if (!ref $self || $self eq __PACKAGE__) {
        $line = $self;
    }

    for my $p (@$MASK_PATTERNS) {
        $line =~ s/$p/[PROTECTED]/gs;
    }
    return $line;
}

sub setLogToProperty {
    my ($param1, $param2) = @_;

    # 1st case, when param 1 is a reference, we are going to set log to property for current object.
    # but if this reference is not a FlowPDF::Log reference, it will bailOut
    if (ref $param1 and ref $param1 ne __PACKAGE__) {
        croak(q|Expected a reference to FlowPDF::Log, not a '| . ref $param1 . q|' reference|);
    }

    if (ref $param1) {
        if (!defined $param2) {
            croak "Property path is mandatory parameter";
        }
        $param1->{logToProperty} = $param2;
        $LOG_TO_PROPERTY = $param2;
        return $param1;
    }
    else {
        if ($param1 eq __PACKAGE__) {
            $param1 = $param2;
        }
        if (!defined $param1) {
            croak "Property path is mandatory parameter";
        }
        $LOG_TO_PROPERTY = $param1;
        $LOGGER->{logToProperty} = $LOG_TO_PROPERTY;
        return 1;
    }
}

sub getLogProperty {
    my ($self) = @_;

    if (ref $self && ref $self eq __PACKAGE__) {
        return $self->{logToProperty};
    }
    return $LOG_TO_PROPERTY;
}

sub setLogToFile {
    my ($param1, $param2) = @_;

    # 1st case, when param 1 is a reference, we are going to set log to file for current object.
    # but if this reference is not a FlowPDF::Log reference, it will bailOut
    if (ref $param1 and ref $param1 ne __PACKAGE__) {
        croak(q|Expected a reference to FlowPDF::Log, not a '| . ref $param1 . q|' reference|);
    }

    if (ref $param1) {
        if (!defined $param2) {
            croak "File path is mandatory parameter";
        }
        $param1->{logToFile} = $param2;
        $LOG_TO_FILE = $param2;
        return $param1;
    }
    else {
        if ($param1 eq __PACKAGE__) {
            $param1 = $param2;
        }
        if (!defined $param1) {
            croak "File path is mandatory parameter";
        }
        $LOG_TO_FILE = $param1;
        $LOGGER->{logToFile} = $LOG_TO_FILE;
        return 1;
    }
}

sub getLogFile {
    my ($self) = @_;

    if (ref $self && ref $self eq __PACKAGE__) {
        return $self->{logToFile};
    }
    return $LOG_TO_FILE;
}

sub getLogLevel {
    my ($self) = @_;

    if (ref $self && ref $self eq __PACKAGE__) {
        return $self->{level};
    }

    return $LOG_LEVEL;
}


sub setLogLevel {
    my ($param1, $param2) = @_;

    if (ref $param1 and ref $param1 ne __PACKAGE__) {
        croak (q|Expected a reference to FlowPDF::Log, not a '| . ref $param1 . q|' reference|);
    }

    if (ref $param1) {
        if (!defined $param2) {
            croak "Log level is mandatory parameter";
        }
        $param1->{level} = $param2;
        $LOG_LEVEL = $param2;
        return $param1;
    }
    else {
        if ($param1 eq __PACKAGE__) {
            $param1 = $param2;
        }
        if (!defined $param1) {
            croak "Property path is mandatory parameter";
        }
        $LOG_LEVEL = $param1;
        $LOGGER->{level} = $LOG_LEVEL;
        return 1;
    }
}
sub new {
    my ($class, $opts) = @_;

    my ($level, $logToProperty, $logToFile);

    if (!defined $opts->{level}) {
        $level = $LOG_LEVEL;
    }
    else {
        $level = $opts->{level};
    }

    if (!defined $opts->{logToProperty}) {
        $logToProperty = $LOG_TO_PROPERTY;
    }
    else {
        $logToProperty = $opts->{logToProperty};
    }

    if (!defined $opts->{logToFile}) {
        $logToFile = $opts->{logToFile};
    }

    my $self = {
        level         => $level,
        logToProperty => $logToProperty,
        logToFile     => $logToFile
    };

    bless $self, $class;
    return $self;
}

sub fwLogInfo {
    my @params = @_;

    if (!ref $params[0] || ref $params[0] ne __PACKAGE__) {
        unshift @params, $LOGGER;
    }
    return info(@params);
}
sub info {
    my ($self, @messages) = @_;
    $self->_log(INFO, @messages);
}


sub fwLogDebug {
    my @params = @_;

    if (!ref $params[0] || ref $params[0] ne __PACKAGE__) {
        unshift @params, $LOGGER;
    }
    return debug(@params);
}
sub debug {
    my ($self, @messages) = @_;
    $self->_log(DEBUG, '[FLOWPDF_DEBUG]', @messages);
}


sub fwLogError {
    my @params = @_;

    if (!ref $params[0] || ref $params[0] ne __PACKAGE__) {
        unshift @params, $LOGGER;
    }
    return error(@params);
}
sub error {
    my ($self, @messages) = @_;
    $self->_log(ERROR, '[FLOWPDF_ERROR]', @messages);
}


sub fwLogWarning {
    my @params = @_;

    if (!ref $params[0] || ref $params[0] ne __PACKAGE__) {
        unshift @params, $LOGGER;
    }
    return warning(@params);
}
sub warning {
    my ($self, @messages) = @_;
    $self->_log(INFO, '[FLOWPDF_WARNING]', @messages);
}


sub fwLogTrace {
    my @params = @_;
    if (!ref $params[0] || ref $params[0] ne __PACKAGE__) {
        unshift @params, $LOGGER;
    }
    return trace(@params);
}
sub trace {
    my ($self, @messages) = @_;
    $self->_log(TRACE, '[FLOWPDF_TRACE]', @messages);
}

sub level {
    my ($self, $level) = @_;

    if (defined $level) {
        $self->{level} = $level;
    }
    else {
        return $self->{level};
    }
}

sub logToProperty {
    my ($self, $prop) = @_;

    if (defined $prop) {
        $self->{logToProperty} = $prop;
    }
    else {
        return $self->{logToProperty};
    }
}


my $length = 40;

sub divider {
    my ($self, $thick) = @_;

    if ($thick) {
        $self->info('=' x $length);
    }
    else {
        $self->info('-' x $length);
    }
}

sub header {
    my ($self, $header, $thick) = @_;

    my $symb = $thick ? '=' : '-';
    $self->info($header);
    $self->info($symb x $length);
}

sub _log {
    my ($self, $level, @messages) = @_;

    return 1 if $level > $self->level;
    my @lines = ();
    for my $message (@messages) {
        if (ref $message) {
            my $t = Dumper($message);
            $t = $self->maskLine($t);
            print $t;
            push @lines, $t;
        }
        else {
            $message = $self->maskLine($message);
            print "$message\n";
            push @lines, $message;
        }
    }

    if ($self->{logToProperty}) {
        my $prop = $self->{logToProperty};
        my $value = "";
        eval {
            $value = $self->ec->getProperty($prop)->findvalue('//value')->string_value;
            1;
        };
        unshift @lines, split("\n", $value);
        $self->ec->setProperty($prop, join("\n", @lines));
    }

    if ($self->{logToFile}) {
        my $file = $self->{logToFile};
        open (my $fh, '>>', $file) || do {
            fwLogWarning("Can't open '$file' for writing logs. Disabling logging into file.");
            $self->setLogToFile('');
        };
        print $fh join("\n", @lines);
    }
    return 1;
}


sub ec {
    my ($self) = @_;
    unless($self->{ec}) {
        require ElectricCommander;
        my $ec = ElectricCommander->new;
        $self->{ec} = $ec;
    }
    return $self->{ec};
}



1;
