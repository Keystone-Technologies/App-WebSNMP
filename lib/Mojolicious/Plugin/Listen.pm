package Mojolicious::Plugin::Listen;
use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.01';

# IPv6 support requires IO::Socket::IP
use constant IPV6 => $ENV{MOJO_NO_IPV6}
  ? 0
  : eval 'use IO::Socket::IP 0.16 (); 1';

# TLS support requires IO::Socket::SSL
use constant TLS => $ENV{MOJO_NO_TLS} ? 0
  : eval(IPV6 ? 'use IO::Socket::SSL 1.75 (); 1'
  : 'use IO::Socket::SSL 1.75 "inet4"; 1');

sub register {
  my ($self, $app) = @_;

  return unless $app->can('config');
    
  unless ( $app->config->{hypnotoad}->{listen} ) {
    $app->config->{hypnotoad}->{listen} = IPV6 ? (TLS ? ['http://[::]:80', 'https://[::]:443'] : ['http://[::]:80'] ) : (TLS ? ['http://*:80', 'https://*:443'] : ['http://*:80'] )
  }

  $ENV{MOJO_LISTEN} = join ',', @{$app->config->{hypnotoad}->{listen}};
}

1;
__END__

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Listen - Mojolicious Plugin

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('Listen');

  # Mojolicious::Lite
  plugin 'Listen';

=head1 DESCRIPTION

L<Mojolicious::Plugin::Listen> is a L<Mojolicious> plugin.

=head1 METHODS

L<Mojolicious::Plugin::Listen> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut
