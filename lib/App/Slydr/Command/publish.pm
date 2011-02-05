package App::Slydr::Command::publish;
# ABSTRACT: Publish your presentation into HTML

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

has 'input_dir' => (
  is          => 'rw' ,
  isa         => 'Str' ,
  cmd_aliases => 'i' ,
  traits      => [ qw/ Getopt / ],
  default     => './input' ,
);

has 'output_dir' => (
  is          => 'rw' ,
  isa         => 'Str' ,
  cmd_aliases => 'o' ,
  traits      => [ qw/ Getopt / ],
  default     => './output' ,
);

has 'publish_all' => (
  is          => 'ro',
  isa         => 'Bool',
  cmd_aliases => 'a',
  traits      => [qw/ Getopt /],
);

has 'verbose' => (
  is          => 'ro',
  isa         => 'Bool',
  cmd_aliases => 'v',
  traits      => [qw/ Getopt /],
);

sub command_names { qw/ publish pub / }

sub execute {
  my( $self , $options , $args ) = @_;

  unless ( -d $self->input_dir ) {
    say "Must have an 'input' directory!";
    exit(1);
  }

  $self->input_dir(  abs_path( $self->input_dir  ));
  $self->output_dir( abs_path( $self->output_dir ));

  my @files;
  if ( @$args ) { @files = map { abs_path( $_ ) } @$args }
  else {         @files = File::Find::Rule->file()->in( $self->input_dir ) }

  $self->process_file( $_ ) foreach @files;
}

sub pretty_print {
  my( $self , $event , $file ) = @_;

  my $i = $self->input_dir;
  $file =~ s|$i/||;

  printf "%8s %s\n" , $event , $file;
}

sub process_file {
  my( $self , $file ) = @_;

  my( $file_name , $dest_dir ) = fileparse( $file );

  my $i = $self->input_dir;
  my $o = $self->output_dir;

  $dest_dir =~ s/$i/$o/;
  make_path( $dest_dir );

  my( $fxn , $destination );

  given( $file ) {
    when ( /\.(html|cgi|css|js|je?pg|gif|png|txt)$/ ) {
      $destination = "$dest_dir/$file_name";
      $fxn = $self->newer_than( $file , $destination ) ? 'skip' : 'copy_file';
    }
    when( m|/([^/]+)\.ya?ml$| ) {
      $destination = "$dest_dir/$1.html";
      $fxn = $self->newer_than( $file , $destination ) ? 'skip' : 'slydr';
    }
    default { $fxn = 'skip' }
  }

  $self->$fxn( $file , $destination );
}

sub copy_file  {
  my( $self , $src , $dst ) = @_;
  copy( $src , $dst ) or die( "Copy of $src failed ($!)" );
  $self->pretty_print( 'COPY' , $src )
}

sub newer_than {
  my( $self , $s , $d ) = @_;
  return if $self->publish_all;
  return unless -e $d;
  return ( -M $s > -M $d );
}

sub skip  {
  my( $self , $i ) = @_;
  $self->pretty_print( 'SKIP' , $i ) if $self->verbose;
}

sub slydr {
  my( $self , $slide_file , $out_file ) = @_;

  my( $meta , $prepped_slides ) = _prep_slides( $slide_file );

  _publish_page( $meta , $prepped_slides , $out_file );

  $self->pretty_print( 'SLYDR' , $slide_file );
}

sub _get_page_tmpl {
  state $page_template;
  return $page_template if $page_template;
  return $page_template = _slurp_file( 'templates/page.tt' );
}

sub _get_slide_tmpl {
  state $slide_template;
  return $slide_template if $slide_template;
  return $slide_template = _slurp_file( 'templates/slide.tt' );
}

sub _get_tmpl_obj {
  state $T;
  return $T if $T;
  $T = Template->new({ POST_CHOMP   => 1 ,
                       PRE_CHOMP    => 1 ,
                       RELATIVE     => 1 ,
                       INCLUDE_PATH => './' });
  return $T;
}

sub _load_slide_file {
  my $file = shift;
  my @slides;

  try {
    @slides = LoadFile( $file );
  }
  catch {
    say "Problem loading '$file':\n$_";
    exit(1);
  };

  return @slides;
}

sub _prep_slides {
  my $file = shift;

  my @slides = _load_slide_file( $file );

  my $meta = $slides[0];
  $meta->{min} = 1 unless $meta->{min};
  $meta->{max} = $#slides unless $meta->{max};

  my $slide_tmpl = _get_slide_tmpl();

  foreach ( 1 .. $#slides ) {
    my $slide = ref $slides[$_] ? $slides[$_] : { content => $slides[$_] };

    $slide->{n} = $_;

    $slide->{content} = _process_content( \( $slide->{content} ) , {} );

    $slides[$_] = _process_content( \$slide_tmpl , { meta => $meta , slide => $slide });
  }

  shift @slides;

  return( $meta , \@slides );
}

sub _publish_page {
  my( $meta , $slides , $out ) = @_;

  my $T         = _get_tmpl_obj();
  my $page_tmpl = _get_page_tmpl();
  $T->process( \$page_tmpl , { meta => $meta , slides => $slides } , $out )
    or die $T->error;
}

sub _process_content {
  my( $content_ref , $tmpl_vars ) = @_;

  my $buffer;

  my $T = _get_tmpl_obj();
  $T->process( $content_ref , $tmpl_vars , \$buffer )
    or die $T->error;

  return $buffer;
}

sub _slurp_file {
  my $file = shift;

  unless ( -e -r $file ) {
    die "Can't find file '$file'!";
    exit(1);
  }

  my $contents = read_file( $file );
  return $contents;
}

__PACKAGE__->meta->make_immutable;
1;

