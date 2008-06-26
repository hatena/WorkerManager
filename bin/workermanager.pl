#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Std;
use Proc::Daemon;
use File::Pid;

use Storable qw(thaw);
use List::Util qw(sum);

use Data::Dumper qw(Dumper);

use FindBin;
use lib File::Spec->catdir($FindBin::Bin, '..', 'lib');
use lib File::Spec->catdir($FindBin::Bin, '..','modules','DBIx-MoCo','lib');
use lib File::Spec->catdir($FindBin::Bin, '..','modules','Ridge','lib');
use lib File::Spec->catdir($FindBin::Bin, '..','modules','Hatena','lib');
use lib File::Spec->catdir($FindBin::Bin, '..','modules','Hatena-Star-Mobile','lib');
use lib File::Spec->catdir($FindBin::Bin, '..','modules','WorkerManager','lib');
use WorkerManager;

sub usage {
    print << "EOF";

 usage: $0 [-hdn] [-c concurrency]

        -h   : this (help) message
        -d   : debug
        -n   : prevent deamonize (non fork)
        -c   : the number of concurrency (default 4).

EOF
;
    exit;
}

my %opt;
my $DEBUG;
my $DAEMON;
my $PIDFILE;
my $LOGFILE;
my $ERRORLOGFILE;
my $MAX_PROCESSES;
my %CHILD_PIDS;
my $wm;

sub init {
    $DEBUG = 0;
    $DAEMON = 1;
    $PIDFILE = "/var/run/workermanager.pid";
    $LOGFILE = "/var/log/workermanager.log";
    $ERRORLOGFILE = "/var/log/workermanager_error.log";
    $MAX_PROCESSES = 4;
    my %opt;
    getopts("hndc:", \%opt);
    usage() if $opt{h};
    return %opt;
}

BEGIN {
    %opt = init;
    $MAX_PROCESSES = $opt{c} if($opt{c});
    $DEBUG = 1 if($opt{d});
    $DAEMON = 0 if($opt{n});
}

sub interrupt {
    my $sig = shift;
    setpgrp;
    $SIG{$sig} = 'IGNORE';
    kill $sig, 0;
    $wm->killall();
    die "killed by $sig";

    exit(0);
}

sub daemonize {
    #my $self = shift;
    #return unless $self->config->{daemon};

    $SIG{INT} = 'interrupt';
    $SIG{HUP} = 'interrupt';
    $SIG{QUIT} = 'interrupt';
    $SIG{KILL} = 'interrupt';
    $SIG{TERM} = 'interrupt';

    my $pid = File::Pid->new({file => $PIDFILE});
    if( $pid->running ){
        die 'The PID in '.$PIDFILE.' is still running.';
    } else {
        if( -e $PIDFILE){
            warn 'The pid file '.$PIDFILE.' is still exist. Try to remove it.';
            $pid->remove
                or die "Failed to remove the pid file.";
        }
    }

    Proc::Daemon::Init;

    if($LOGFILE){
        open(STDOUT, ">>".$LOGFILE)
            or die "Failed to re-open STDOUT to ".$LOGFILE;
    }
    if($ERRORLOGFILE){
        open(STDERR, ">>".$ERRORLOGFILE)
            or die "Failed to re-open STDERR to ".$ERRORLOGFILE;
    }
    if($PIDFILE){
        my $pid = File::Pid->new({file => $PIDFILE});
        if( -e $PIDFILE){
            $pid->remove
                or die "Failed to remove the pid file.";
        }
        $pid->write;
    }
}

daemonize if $DAEMON;

$wm = WorkerManager->new(
    max_processes => $MAX_PROCESSES,
    type => 'TheSchwartz',
    worker => 'Hatena::Star::Worker::UpdateFavorites',
);

$wm->main();

END {
    $wm->killall() unless $DAEMON;
}
