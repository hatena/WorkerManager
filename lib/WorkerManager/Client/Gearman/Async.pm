package WorkerManager::Client::Gearman::Async;
use strict;
use warnings;
use base qw(WorkerManager::Client::Gearman);

sub insert {
    my $self = shift;
       $self->client->dispatch_background(@_);
}

1;
