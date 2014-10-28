use strict;
use warnings;
use v5.10;
use FindBin ();
use lib $FindBin::Bin;
use testlib;
use Test::More tests => 3;
use FFI::TinyCC;
use FFI::Raw;
use File::Temp qw( tempdir );
use File::chdir;
use Config;

subtest 'c source code' => sub {
  plan tests => 2;

  my $tcc = FFI::TinyCC->new;
  
  my $file = _catfile($FindBin::Bin, 'c', 'return22.c');
  note "file = $file";
  
  eval { $tcc->add_file($file) };
  is $@, '', 'tcc.compile_string';

  is $tcc->run, 22, 'tcc.run';
};

subtest 'obj' => sub {

  plan tests => 2;
  
  local $CWD = tempdir( CLEANUP => 1 );
  
  my $obj = _catfile($CWD, "foo$Config{obj_ext}");
  
  subtest 'create' => sub {
    plan tests => 3;
    my $tcc = FFI::TinyCC->new;
    
    eval { $tcc->set_output_type('obj') };
    is $@, '', 'tcc.set_output_type(obj)';
    
    eval { $tcc->compile_string(q{
      const char *
      roger()
      {
        return "rabbit";
      }
    })};
    is $@, '', 'tcc.compile_string';
  
    note "obj=$obj";
    eval { $tcc->output_file($obj) };
    is $@, '', 'tcc.output_file';
  };
  
  subtest 'use' => sub {
  
    plan tests => 4;
  
    my $tcc = FFI::TinyCC->new;
    
    eval { $tcc->add_file($obj) };
    is $@, '', 'tcc.add_file';
    
    eval { $tcc->compile_string(q{
      extern const char *roger();
      const char *wrapper()
      {
        return roger();
      }
    })};
    is $@, '', 'tcc.compile_string';
  
    my $ffi = eval { $tcc->get_ffi_raw('wrapper', FFI::Raw::str) };
    is $@, '', 'tcc.get_ffi_raw';
    
    is $ffi->call, "rabbit", 'ffi.call';
  
  };

};

subtest 'dll' => sub {

  # TODO: on windows can we create a .a that points to
  # the dll and use that to indirectly add the dll?
  plan skip_all => 'unsupported on windows' if $^O eq 'MSWin32';
  plan tests => 2;
  
  local $CWD = tempdir( CLEANUP => 1 );
  
  my $dll = _catfile( $CWD, "bar." . FFI::TinyCC::_dlext() );

  subtest 'create' => sub {
    plan tests => 3;
    my $tcc = FFI::TinyCC->new;
    
    eval { $tcc->set_output_type('dll') };
    is $@, '', 'tcc.set_output_type(dll)';
    
    eval { $tcc->compile_string(q{
      const char *
      roger()
      {
        return "rabbit";
      }
    })};
    is $@, '', 'tcc.compile_string';
  
    note "dll=$dll";
    eval { $tcc->output_file($dll) };
    is $@, '', 'tcc.output_file';
  };
  
  subtest 'use' => sub {
  
    plan tests => 4;
  
    my $tcc = FFI::TinyCC->new;
    
    eval { $tcc->add_file($dll) };
    is $@, '', 'tcc.add_file';
    
    eval { $tcc->compile_string(q{
      extern const char *roger();
      const char *wrapper()
      {
        return roger();
      }
    })};
    is $@, '', 'tcc.compile_string';
  
    my $ffi = eval { $tcc->get_ffi_raw('wrapper', FFI::Raw::str) };
    is $@, '', 'tcc.get_ffi_raw';
    
    is $ffi->call, "rabbit", 'ffi.call';

  };
  
};
