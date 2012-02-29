watch( '(.*)\.rst' )  {|md| system("sphinx-cook -f pdf .") }
watch( 'cover.tex' )  {|md| system("sphinx-cook -f cover .") }
