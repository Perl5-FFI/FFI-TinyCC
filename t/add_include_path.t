use Test2::V0 -no_srand => 1;
use FindBin;
use FFI::TinyCC;
use Path::Class qw( file dir );

my $tcc = FFI::TinyCC->new;

my $inc = file($FindBin::Bin, 'c');

note "inc=$inc";

eval { $tcc->add_include_path($inc) };
is $@, '', 'tcc.add_include_path';

eval { $tcc->compile_string(q{
#include "foo.h"
int 
main(int argc, char *argv[])
{
  return VALUE_22;
}
})};
is $@, '', 'tcc.compile_string';

is eval { $tcc->run }, 22, 'tcc.run';

done_testing;
