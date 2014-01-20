package App::WebSNMP;

use Mojo::Base 'Mojolicious';

sub startup {
  my $self = shift;

  $self->plugin('Config' => {default => {}});
  $self->plugin('Listen');
  $self->plugin('WebSNMP');

  # Test routes
  $self->routes->get('/')->to(cb => sub { shift->render(text => "Hello, World!\n") });
}

1;
