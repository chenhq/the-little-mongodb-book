watch( '(.*)\.rst' )  {|md| system("sphinx-cook .") }
