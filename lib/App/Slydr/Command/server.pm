package App::Slydr::Command::server;
# ABSTRACT: simple Plack-based static file server

use Moose;
extends 'App::Slydr::Command';

use strictures 1;
use Modern::Perl;

use Plack::Runner;

has port => (
  is            => 'ro' ,
  isa           => 'Int' ,
  traits        => [ 'Getopt' ] ,
  cmd_aliases   => 'p' ,
  documentation => 'port to run the server on. Default=5000' ,
  lazy          => 1 ,
  builder       => '_build_port' ,
);

sub _build_port {
  my $self = shift;

  return $self->{port} if defined $self->{port};

  return 5000;
}

sub execute {
  my( $self , $opts , $args ) = @_;

  my $app = App::Slydr::Server->new( root => $self->output_dir )->to_app;

  my $runner = Plack::Runner->new();
  $runner->parse_options( '-p' , $self->port );
  $runner->run($app);
}

__PACKAGE__->meta->make_immutable;

package                         # hide...
  App::Slydr::Server;

use parent 'Plack::App::File';

sub locate_file  {
  my ($self, $env) = @_;

  my $path = $env->{PATH_INFO} || '';

  $path =~ s|^/|| unless $path eq '/';

  if ( -e -d $path and $path !~ m|/$| ) {
    $path .= '/';
    $env->{PATH_INFO} .= '/';
  }

  $env->{PATH_INFO} .= 'index.html'
    if ( $path && $path =~ m|/$| );

  return $self->SUPER::locate_file( $env );
}

1;
