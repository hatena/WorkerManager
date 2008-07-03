#! /usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib File::Spec->catdir($FindBin::Bin, '..', 'lib');
use lib File::Spec->catdir($FindBin::Bin, '..', '..', 'lib');

use WorkerManager::Client::TheSchwartz;

my $client = WorkerManager::Client::TheSchwartz->new();
$client->insert('Sandbox::Worker::A' => +{foo => "bar"});
#$client->insert('Sandbox::Worker::B' => +{foo => "bar2"});
