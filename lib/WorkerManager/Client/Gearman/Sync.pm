package WorkerManager::Client::Gearman::Sync;
use strict;
use warnings;
use base qw(WorkerManager::Client::Gearman);

sub insert {
    my $self = shift;
       $self->client->do_task(@_);
}

1;
