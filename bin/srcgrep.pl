#!/usr/bin/perl
#
# Grapnel.js
# https://github.com/gregsabia/srcgrep
#
# @author Greg Sabia
# @author Stephen Chow
# @link http://gregsabia.com
# @version 0.1.0
# 
# Released under MIT License. See LICENSE.txt or http://opensource.org/licenses/MIT
#

use strict;
use Date::Format;
use Getopt::Long;

# Default search parameters (can be overridden in command line)
my @source_paths  = (
    '/var/www/sites'
);

my @exclude_files = (
    '*.avi',
    '*.m4v',
    '*.jpe?g',
    '*.swf',
    '*.flv',
    '*.avi',
    '*.mov',
    '*.svn-base',
    '*.svn',
    '*.csv',
    '*.tar',
    '*.gz',
    '*.zip',
);

# Configuration variables
(my $self  = $0) =~ s#.*/##;
my $date   = time2str ("%Y%m%d-%H%M", time);
$ENV{PATH} = "/bin:/usr/bin:$ENV{PATH}" unless ($ENV{PATH} =~ /\/usr\/bin/);

# Executables needed later
my $grep = 'grep';
my @grep_opts = ('-H', '-n', '-r', '-I', '--mmap');
my $find = 'find';

my $tee = 'tee';
my $out_file = "/tmp/$self-$date.txt";

# Get options from command line
my ($path, $ignore, @regexp, $test, $outfile, @patterns, @excludes);
Getopt::Long::Configure ("bundling");
GetOptions (
    "i|ignore" => \$ignore,
    "p|path:s" => \$path,
    "e|regexp=s" => \@regexp,
    "t|test" => \$test,
    "o|outfile" => \$outfile,
    "h|help" => sub {&usage }
);

# Check options
push (@grep_opts, '-i') if $ignore;

if ("$path") {
    die "'$path' is not a valid path. See $self --help.\n" unless (-d $path);
    @source_paths = ("$path");
}

die "No search patterns specified. See $self --help.\n" unless @regexp;

foreach my $pattern (@regexp) {
    chomp;
    push (@patterns, "-e '$pattern'");
} 

foreach my $exclude (@exclude_files) {
    chomp;
    push (@excludes, "--exclude '$exclude'");
}

foreach my $dir (@source_paths) {
    chomp;
    next unless -d $dir;

    my $cmd = "$grep @grep_opts @excludes @patterns $dir";
    $cmd = "$cmd | tee $out_file" if ($outfile);
    my @find_opts = ("-wholename '*.svn'", '-prune', '-o', '-type', 'f', '-exec', "$grep", "@grep_opts", "@excludes", "@patterns", '{}', '\;');
    my $cmd2 = "find $dir @find_opts";

    if ($test) {
        print "The '$self' command would be: \n    $cmd\n";
        print "The '$self' command would be: \n    $cmd2\n";
    } else {
        exec ($cmd2);
    }
}

# Functions
sub usage () {
    print "\nUsage:  $self [OPTIONS] -e PATTERN [-e PATTERN, -e ...]\n\n

    The output will be in FILENAME:LINE#:LINE format convenient for gvim.

    Options:

    -h, --help     This usage statement.

    -i, --ignore   Ignore case when searching.

    -o, --outfile  Produce an outfile of results in /tmp.  The file
        will be named $self-YYYYmmddHHMMSS.

    -t, --test     Do not run the search, but print the command instead.

    -p, --path     Path to search.  If left empty, the script will try to
        find the source directory.

    -e, --regexp   Search pattern using regular expressions. Additional
        patterns will result in OR searches


    EXAMPLES:

    To find source files matching either 'File' or 'Foo bar':
    $self -e File -e 'Foo bar'

    To find files in /tmp with lines starting with Test or test:
    $self -i -p /tmp -e '^test'
    ";

    exit 0;
}
