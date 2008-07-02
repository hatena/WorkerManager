package Sandbox::Worker::B;
use strict;
use warnings;
use base qw( TheSchwartz::Worker );
use TheSchwartz::Job;

sub work {
    my $class = shift;
    my TheSchwartz::Job $job = shift;

    print "Processing 'B' arg foo:".$job->arg->{foo}."\n";

    $job->completed();
}

1;
