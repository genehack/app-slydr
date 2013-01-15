package App::Slydr::Command;
# ABSTRACT: Base command class

use Moose;
extends 'MooseX::App::Cmd::Command';

use strictures 1;
use feature 'state';
use Modern::Perl;

use Cwd               qw/ abs_path  /;
use File::Basename;
use File::Copy;
use File::Find::Rule;
use File::Path        qw/ make_path /;
use File::Slurp;
use Getopt::Std;
use Template;
use Try::Tiny;
use YAML              qw/ LoadFile  /;

has input_dir => (
  is          => 'rw' ,
  isa         => 'Str' ,
  cmd_aliases => 'i' ,
  traits      => [ qw/ Getopt / ],
  default     => './input' ,
);

has output_dir => (
  is          => 'rw' ,
  isa         => 'Str' ,
  cmd_aliases => 'o' ,
  traits      => [ qw/ Getopt / ],
  default     => './output' ,
);

has verbose => (
  is          => 'ro',
  isa         => 'Bool',
  cmd_aliases => 'v',
  traits      => [qw/ Getopt /],
);

sub execute {
  my( $self , $opts , $args ) = @_;

  if ( $opts->{help_flag} ) {
    print $self->usage->text;
    exit;
  }

  $self->_run( $opts , $args );
}


__PACKAGE__->meta->make_immutable;
1;
