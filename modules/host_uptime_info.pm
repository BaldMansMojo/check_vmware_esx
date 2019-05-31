sub host_uptime_info
   {
   my ($host, $maintenance_mode_state) = @_;
   my $state = 2;
   my $output = 'HOST UPTIME Unknown error';
   my $value;

   $values = return_host_performance_values($host, $maintenance_mode_state, 'sys', ('uptime.latest'));

   if (defined($values))
      {
      $value = simplify_number(convert_number($$values[0][0]->value), 0);
      }

   if (defined($value))
      {
      $state = 0;
      $output =  "uptime=" . duration_exact($value);
      }
   return ($state, $output);
   }

# A module always must end with a returncode of 1. So placing 1 at the end of a module 
# is a common method to ensure this.
1;
