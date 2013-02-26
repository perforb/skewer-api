use inc::Module::Install;
name 'Skewer';
version '1.0';

requires 'Plack';
requires 'Starman';
requires 'JSON';
requires 'YAML';
requires 'Log::Dispatch';
requires 'Log::Dispatch::Config';
requires 'Project::Libs';
requires 'Redis';
requires 'WebService::Simple';
requires 'Config::ENV';
requires 'Config::Pit';

WriteAll;
