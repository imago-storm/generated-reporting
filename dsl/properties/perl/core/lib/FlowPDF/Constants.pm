package FlowPDF::Constants;
use base qw/Exporter/;

use strict;
use warnings;
use constant {
    # Property in configuration where debug level is being stored.
    # this property is being used for automatic debug level setup.
    DEBUG_LEVEL_PROPERTY             => 'debugLevel',

    # Proxy related constants
    HTTP_PROXY_URL_PROPERTY          => 'httpProxyUrl',
    PROXY_CREDENTIAL_PROPERTY        => 'proxy_credential',

    # auth related constants
    AUTH_SCHEME_PROPERTY             => 'authScheme',
    AUTH_SCHEME_VALUE_FOR_BASIC_AUTH => 'basic',
    AUTH_SCHEME_VALUE_FOR_OAUTH_V1   => 'oauth',
    AUTH_SCHEME_VALUE_FOR_BEARER     => 'bearer',
    BASIC_AUTH_CREDENTIAL_PROPERTY   => 'basic_credential',
    # This is not supported yet, so it is not exposed.
    OAUTH_CREDENTIAL_PROPERTY        => 'oauth_credential',
};

our @EXPORT_OK = qw/
    DEBUG_LEVEL_PROPERTY
    HTTP_PROXY_URL_PROPERTY
    PROXY_CREDENTIAL_PROPERTY
    AUTH_SCHEME_PROPERTY
    AUTH_SCHEME_VALUE_FOR_BASIC_AUTH
    AUTH_SCHEME_VALUE_FOR_OAUTH_V1
    AUTH_SCHEME_VALUE_FOR_BEARER
    BASIC_AUTH_CREDENTIAL_PROPERTY
/;

1;
