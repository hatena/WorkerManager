#! /usr/bin/perl

use strict;
use warnings;

my $client = WorkerManager::Client::TheSchwartz->new();
$client->insert('Sandbox::Worker::A' => +{foo => "bar"});
