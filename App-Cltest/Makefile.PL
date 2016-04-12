use 5.022001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'App::Cltest',
    VERSION_FROM      => undef, # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    # ABSTRACT_FROM     => 'lib/Cltest/Test.pm', # retrieve abstract from module
    AUTHOR            => 'electricface <songwentai@linuxdeepin.com>',
    #LICENSE           => 'perl',
    #Value must be from legacy list of licenses here
    EXE_FILES         => ['bin/cltest.pl'],
);
