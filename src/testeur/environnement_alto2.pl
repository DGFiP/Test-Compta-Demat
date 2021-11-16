#!/usr/bin/perl -- -*- C -*- 

# suivant l utilisation locale des utilisateurs les chemins sont a modifier
sub Env_Path { 
		$ENV{ProgramFiles} = "/A/MODIFIER/chemin/vers/src"; 
		$ENV{ProgramData} = "/A/MODIFIER/chemin/vers/src"; 
} 
1; #return true 

