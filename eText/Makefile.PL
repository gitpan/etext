use ExtUtils::MakeMaker qw(&WriteMakefile);
use Cwd;

$Version = '0.52';
$Tk::MMutil::dir = cwd unless defined $Tk::MMutil::dir;

my $dirTk;

local $inc    = $::inc || "";
$xlib   = $::xlib || "" if not defined $xlib;
$dirTk = ".." if -r "../tkGlue.h";	# Check whether we are in the Tk tree.
unless (defined $dirTk) {
  # We are compiled standalone, try my machine locations:
  #$dirTk = "H:/get/perl/Tk400.200" if -r "H:/get/perl/Tk400.200/tkGlue.h";
  $dirTk = "H:/get/perl/Tk401.000.pm" if -r "H:/get/perl/Tk401.000.pm/tkGlue.h";
}

# If $dirTk is not defined, try to find it

unless (defined $dirTk) {
  if (-r "../Tk/tkGlue.h") {$dirTk = "../Tk";}
  elsif (-r "Tk/tkGlue.h") {$dirTk = "Tk" }
  elsif (-r "../../tkGlue.h") {$dirTk = "../.." }
  elsif (-r "../../Tk/tkGlue.h") {$dirTk = "../../Tk" }
  # Try harder
  elsif (@list = <../../Tk-*> and -d $list[-1]) {$dirTk = $list[-1] }
  elsif (@list = <../Tk-*> and -d $list[-1]) {$dirTk = $list[-1] }
  die "Please define \$dirTk in Makefile.PL, cannot find it automatically.\n"
    unless defined $dirTk;
}

{
  my $d = cwd;
  chdir $dirTk or die "cannot chdir `$dirTk': $!";
  $dirTk = cwd;
  chdir $d or die "cannot chdir `$d': $!";
}

print "Tk found in $dirTk.\n";

$common::dirTk = $dirTk;	# Communicate to the child

eval 'use lib $dirTk';
require Tk::MMutil;

#$win_arch = 'open32';
eval 'use Tk::Config';		# Get the constants if standalone

local $Tk::MMutil::define = $Tk::MMutil::define;
$Tk::MMutil::define .= " -DLangIsPerl";

$newTk = $dirTk !~ /400/;
$Tk::MMutil::define .= " -DNEW_TK" if $newTk;
$mylibs = $newTk ? "" : "$xlib -lX11" ;
$myinc = $::inc || $inc;

$direText = "pTk";
$gccopt = $::gccopt if $::gccopt;

Tk::MMutil::TkExtMakefile(
    NAME     => 'Tk::eText',
    VERSION  => $Version,
    MYEXTLIB => "$direText/libpTkeText\$(LIB_EXT)",
    LIBS    => [ $mylibs ],
    INC     => "-I$dirTk/pTk $myinc -I$dirTk/pTk/mTk/Xlib $gccopt",
    OBJECT      => 'eText$(OBJ_EXT)',
);


sub MY::constants {
  my $self = shift;
  my $c = $self->MM::constants;
  if ($c =~ m,^INC\b.*/xlib($|\s),m) {
    $c =~ s,^INC\b.*,$& -I$dirTk/pTk/mTk/xlib,m ;
  }
  $c;
}

sub MY::post_constants {

 return # &upgrade_pic() . 
"
TK_DIR = $dirTk
eText_DIR = $direText
";
}

sub MY::postamble {
    '
Makefile     : $(TK_DIR)/myConfig 
$(BASEEXT)$(OBJ_EXT) : $(MYEXTLIB)

$(MYEXTLIB)  : FORCE
	cd $(eText_DIR); $(MAKE) libpTkeText$(LIB_EXT)

#$(eText_DIR)/Makefile : $(eText_DIR)/Makefile.PL
#	cd $(eText_DIR); $(PERL) Makefile.PL

eText.xs : $(TK_DIR)/Text/Text.xs
	cp $(TK_DIR)/Text/Text.xs $@
	perl -pi~ -e "s/([^_])Text/\1eText/g;" -e "s/\"text/\"etext/g" $@

eText.pm : $(TK_DIR)/Text/Text.pm cnvrt eText.xs
	cp $(TK_DIR)/Text/Text.pm $@
	perl -pi~ cnvrt $@

';
}

