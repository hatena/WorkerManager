use inc::Module::Install;

name 'WorkerManager';
version 0.0001;

requires 'Danga::Socket';
requires 'File::Pid';
requires 'Parallel::ForkManager';
requires 'Proc::Daemon';
requires 'TheSchwartz';
requires 'TheSchwartz::Simple';
requires 'UNIVERSAL::require';
recommends 'Gearman::Client';
recommends 'Gearman::Client::Async';

WriteAll;
