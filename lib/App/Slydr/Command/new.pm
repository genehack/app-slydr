package App::Slydr::Command::new;
# ABSTRACT: create a new slydr presentation

use Moose;
extends 'MooseX::App::Cmd::Command';

use strictures 1;
use Modern::Perl;

use File::Copy;
use File::Path qw/ make_path /;
use File::ShareDir qw/ dist_file /;
use Try::Tiny;

sub execute {
  my( $self , $options , $args ) = @_;

  my $name = shift @$args
    or die "Need a presentation name!";

  _confirm_name( $name );
  _make_dir_tree( $name );

  my %files = (
    'css/slydr.css'      => 'input/css/' ,
    'js/slydr.js'        => 'input/js/'  ,
    'templates/page.tt'  => 'templates/' ,
    'templates/slide.tt' => 'templates/' ,
  );

  for my $file ( keys %files ) {
    my $dest = $files{$file};
    my $path = _find_share_file( 'App-Slydr' , $file );
    copy( $path , "$name/$dest" );
  }
}

sub _confirm_name {
  my $name = shift;

  if ( -e $name and ! -d $name ) {
    say "'$name' exists and is not a directory";
    exit(1);
  }
  elsif ( -d $name ) {
    print "Directory '$name' exists - okay to use it? ";
    chomp( my $answer = <STDIN> );
    exit(1) unless $answer =~ /^y/i;
  }
}

sub _find_share_file {
  my( $dist , $file ) = @_;

  my $file_path;

  try {
    $file_path = dist_file( $dist , $file );
  }
  catch {
    $file_path = "$FindBin::RealBin/../share/$file";
    die $_ unless -e -r $file_path;
  };

  return $file_path;
}

sub _make_dir_tree {
  my $name = shift;
  my @dirs = map { "$name/$_" } ( qw| templates input/css input/js output | );
  make_path( @dirs );
}

__PACKAGE__->meta->make_immutable;
1;
