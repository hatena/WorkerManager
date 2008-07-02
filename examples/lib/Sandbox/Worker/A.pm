package Sandbox::Worker::A;
use strict;
use warnings;
use base qw( TheSchwartz::Worker );
use TheSchwartz::Job;

sub work {
    my $class = shift;
    my TheSchwartz::Job $job = shift;

    print "Processing 'A'\n";

    $job->completed();
}

1;
