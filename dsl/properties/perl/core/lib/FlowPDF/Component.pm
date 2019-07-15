=head1 NAME

FlowPDF::Component

=head1 AUTHOR

CloudBees

=head1 DESCRIPTION

This module provides a base class for FlowPDF Components.

Each FlowPDF Component is a perl module which should have init($initParams) method and be a subclass of FlowPDF::Component.

=head1 USAGE

To create a component one should define a class that inherits this class and define an init($class, $params) method to make it working.
Also, components should be loading using L<FlowPDF::ComponentManager>, please, avoid direct usage of components modules.

Direct usage of components will be prohibited in the next release.

Example of a simple component:

%%%LANG=perl%%%

    package FlowPDF::Component::MyComponent
    use base qw/FlowPDF::Component/;
    use strict;
    use warnings;

    sub init {
        my ($class, $initParams) = @_;
            my ($initParams) = @_;
            my $retval = {%$initParams};
            bless $retval, $class;
            return $retval;
    }

    sub action {
        my ($self) = @_;
        print "Doing Action!";
    }

%%%LANG%%%

Then, to load this component using L<FlowPDF::ComponentManager> one should use its loadComponent method.

Please, note, that loadComponent loads component globally, that is, you don't need to do loadComponent with parameters again and again.

You need to call getComponent('FlowPDF::Component::YourComponent') of L<FlowPDF::ComponentManager>.

Please, note, that in that case getComponent() will return exactly the same object that was created during component loading.

To get more details about component loading see L<FlowPDF::ComponentManager>

Example:

%%%LANG=perl%%%

    my $component = FlowPDF::ComponentManager->loadComponent('FlowPDF::Component::MyComponent', $initParams);
    # then you can use your component across your code.
    # to do that, you need to get this component from anywere in current runtime.
    ...;
    sub mySub {
        # the same component object.
        my $component = FlowPDF::ComponentManager->getComponent('FlowPDF::Component::MyComponent');
    }

%%%LANG%%%

=head1 AVAILABLE COMPONENTS

Currently there are 3 components that are going with L<FlowPDF>:

=over 4

=item L<FlowPDF::Component::Proxy>

=item L<FlowPDF::Component::CLI>

=item L<FlowPDF::Component::OAuth>

=back

=cut

package FlowPDF::Component;
use base qw/FlowPDF::BaseClass2/;
use FlowPDF::Types;

__PACKAGE__->defineClass({
        componentInitParams => FlowPDF::Types::Reference('HASH')
});

use strict;
use warnings;

sub isEFComponent {
    return 0;
}

1;
