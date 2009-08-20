package WorkerManager::Client::Gearman;
use strict;
use warnings;
use Gearman::Client;
use base qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw(client));

sub new {
    my ($class, $args) = @_;
    $args->{job_servers} ||= [qw(127.0.0.1)];

    my $self = $class->SUPER::new($args);
       $self->client = Gearman::Client->new(job_servers => $args->{job_servers});
       $self;
}

1;
