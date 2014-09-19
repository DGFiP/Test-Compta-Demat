#!/usr/bin/perl

#Copyright (C) 2014 Direction Generale des Finances Publiques
#
#This software is governed by the CeCILL license under French law and
#abiding by the rules of distribution of free software.  You can  use,
#modify and/ or redistribute the software under the terms of the CeCILL
#license as circulated by CEA, CNRS and INRIA at the following URL
#"http://www.cecill.info".
#
#As a counterpart to the access to the source code and  rights to copy,
#modify and redistribute granted by the license, users are provided only
#with a limited warranty  and the software's author,  the holder of the
#economic rights,  and the successive licensors  have only  limited
#liability.
#
#In this respect, the user's attention is drawn to the risks associated
#with loading,  using,  modifying and/or developing or reproducing the
#software by the user in light of its specific status of free software,
#that may mean  that it is complicated to manipulate,  and  that  also
#therefore means  that it is reserved for developers  and  experienced
#professionals having in-depth computer knowledge. Users are therefore
#encouraged to load and test the software's suitability as regards their
#requirements in conditions enabling the security of their systems and/or
#data to be ensured and,  more generally, to use and operate it in the
#same conditions as regards security.
#
#The fact that you are presently reading this means that you have had
#knowledge of the CeCILL license and that you accept its terms.
#
#!/usr/bin/perl   

# Vérifier que les définitions des appelants sont faites avant la ligne require et avec our
use utf8;
no utf8;
use DBI;
use Config;
use XML::Simple;
use Net::LDAP;
use Net::Ping;
use File::Copy;
use File::Basename;

$OS = $Config{osname};
our %log_type;
our %log_type_nb;

sub isotoutf8 ( ) {

#use Encode;
#RG:T:fonction encode en utf8, vérification que l'entree est en iso (si utf8 => conv en iso au préalable ) :I
	$_ = shift;
	my $iso = &conv_to_iso($_);

	# la chaine forcée en iso est conv en utf8
	$utf8 = enc_utf8($iso);
	return $utf8;
}

sub enc_utf8() {
	use Encode;
	my $iso  = shift;
	my $utf8 = encode_utf8($iso);
	return $utf8;
}

sub connexion () {
	my ( $dbname, $dbhl, $connexion ) = @_;
	my $username;
	my $password;
	if ( ${OS} =~ m/linux/i ) {
		$dbconnect = "dbi:Pg";
	}
	else {
		eval "use DBD::Pg";
		if ($@) {
			$dbconnect = "dbi:PgPP";
		}
		else {
			$dbconnect = "dbi:Pg";
		}
	}

	if ( defined $connexion ) {
		( $username, $password, $host ) = split /\|/, $connexion;

	}
	else {
		$username = "postgres";
		$password = "postgres";

		$host = "localhost";
	}

	$dbhl->disconnect() if ( defined($dbhl) );
	$dbhl = DBI->connect( "${dbconnect}:dbname=$dbname;host=$host",
		$username, $password )
	  or &erreur( "E", "$DBI::errstr" );

	# DBI->trace( 2 ); pour détailler les traces
	return $dbhl;
}

sub connexion_log () {
	my ( $dbname, $dbhl, $create ) = @_;
	$dbhl->disconnect() if ( defined($dbhl) );
	$dbhl = DBI->connect( "dbi:SQLite:dbname=" . "log/${dbname}.db",
		"", "", { RaiseError => 1, sqlite_unicode => 1, } )
	  or die $DBI::errstr;

	#$dbhl->do("PRAGMA cache_size = 2000000");
	$dbhl->do(
"PRAGMA synchronous = OFF ;"
	);

	if ( ( !defined $create ) || ( $create != "nocreate" ) ) {
		my $ref_dump =
		  $dbhl->selectall_hashref( "select id_type,fixe_log from log_type",
			'id_type' );
		foreach my $id_ecr ( keys %$ref_dump ) {

			my $log_temp = &conv_to_iso( $ref_dump->{$id_ecr}->{fixe_log} );

			$log_type{$log_temp} = $id_ecr;
		}
	}
	return $dbhl;
}

sub maj_log() {
	my ($dbhl) = @_;

	# $dbhl->do("COMMIT;");
	$dbhl->do("PRAGMA synchronous = FULL ;");
	$| = 1; # Disable output buffering

	$dbhl->do("drop table if exists log_type ;");
	$dbhl->do(
		"CREATE TABLE  if not exists log_type
( id_type INTEGER   ,
  fixe_log text   unique on conflict ignore
)  "
	) or print STDERR  $DBI::errstr ;

	foreach
	  my $id_ecr ( sort { $log_type{$a} <=> $log_type{$b} } keys %log_type )
	{
		#print STDOUT "\n maj_log : ". $log_type{$id_ecr} . $id_ecr ;
		my $index_id = $log_type{$id_ecr};
		$id_ecr =~ s/\'/\'\'/g;
		$REQ =
"INSERT into log_type (id_type,fixe_log) values ( $index_id ,'$id_ecr');";

		$dbhl->do($REQ)
		  or &trace( " Insert en table fixe_log impossible", '' );
	}

	return 1;
}

sub create_log() {
	my ($fic_log) = @_;
	my $dbh_safe = $dbh;
	my $dbhl = &connexion_log( "altoweb2", $dbh );
	$| = 1; # Disable output buffering

	# log info
	$dbh = $dbhl;
	open( FL, "> log/log_" . basename($fic_log) . ".log" )
	  or ( print STDERR "Impossible de tracer les logs" && return 1 );

	my @dump = &sql_1col(
"select distinct id_ligne,replace(replace (t.fixe_log,'#1',ifnull(l.val1,'')),'#2',ifnull(l.val2,'')) 
from log_alim l, log_type t 
where id_trait = $log_seq and type_log='I' and t.id_type=l.texte_log order by 1 ;"
	, "Supprime 1ere colonne");

	print FL join( "\n", @dump );

	close(FL);

	# log E et A
	open( FL, "> log/err_" . basename($fic_log) . ".log" )
	  or ( print STDERR "Impossible de tracer les logs" && return 1 );

	@dump = &sql_1col(
"select distinct id_ligne,replace(replace (t.fixe_log,'#1',l.val1),'#2',l.val2) fixe
from log_alim l, log_type t 
where id_trait = $log_seq and type_log in ('A','E')   and t.id_type=l.texte_log order by 1 ;"
	);
	print FL join( "\n", @dump );
	close(FL);
	&deconnexion($dbhl);
	$dbh = $dbh_safe;
	return "log/err_" . basename($fic_log) . ".log";

}

sub deconnexion() {
	my ($dbhl) = @_;
	$dbhl->disconnect() if ( defined($dbhl) );
}

sub recup_noseq() {

#
# my @seq_suivi = $dbhlog->selectrow_array("select currval('suivi_alim_id_trait_seq');");

	my @seq_suivi = $dbhlog->selectrow_array(
		"select seq from sqlite_sequence where name ='suivi_alim'; ");
	return $seq_suivi[0];
}

sub conv_to_iso() {

#RG:T:fonction encode en iso, vérification que l'entree est en utf8 ; si utf8 => conv en iso :I
	use Encode;
	$_ = shift;
	my $utf8;
	$_ =~ s/\x{20AC}/~E/;

	# vérification si la chaine est en utf8

	# print STDERR $_ ;
	eval { $utf8 = decode( "utf-8", $_, Encode::FB_CROAK ) };

	# sinon decode chaine iso en var perl interne
	if ($@) {
		$utf8 = decode( "iso-8859-15", $_ );    #, Encode::FB_WARN );
	}
	return $utf8;
}

sub supprime_accent ( ) {
	my ($utf) = @_;
	if ( $utf =~ /^\s*$/ ) { return ""; }

	# my $iso = $utf;
	my $iso = &conv_to_iso($utf);
	$iso =~ s/[^A-Za-z0-9]/_/g;

	return $iso;

	# $iso =~ s/[ÈÉÊËèéêë]/e/ig;  # supp €
	# $iso =~ s/[ÀÁÂÃÄÅÆâãäåæàá]/a/ig;
	# $iso =~ s/[Ð]/d/ig;
	# $iso =~ s/[Ññ]/n/ig;
	# $iso =~ s/[ÌÍÎÏìíîï]/i/ig;
	# $iso =~ s/[ÙÚÛÜüùûúµ]/u/ig;
	# $iso =~ s/[ÒÓÔÕÖØŒðòóõöœô]/o/ig;
	# $iso =~ s/[Ç©ç]/c/ig;
	# $iso =~ s/[ŠŠ]/s/ig;
	# $iso =~ s/[ÝŸýÿ]/y/ig;
	# $iso =~ s/[ª²³¹º]/_/ig;
	# $iso =~ s/[^\n\r\w:,\+\=&-;\|\/\.()"%'\s\$]/_/ig;
	# $iso =~ s/\s+$//;
	# return $iso;
}

sub utf8toutf8 ( ) {

	#RG:T:fonction decodage interne utf8 => raw:I
	my ($iso) = @_;
	my $utf8 = &isotoutf8($iso);
	utf8::decode($utf8);
	return ($utf8);
}

sub erreur() {
	my ( $type, $log ) = @_;
	if ( defined($dbhlog) ) {

		my $log_init = $log;
		my $val_1    = "";
		my $val_2    = "";
		if (
			(
				$log_init =~
m/^(.+):([A-Za-z0-9\-\._,\/ ]+):(.+):([A-Za-z0-9\.,_\-\/ ]+):(.*)$/
			)
			|| ( $log_init =~ m/^(.+):([A-Za-z0-9\-\._,\/ ]+):( .*)$/ )
			|| ( $log_init =~
m/^(.+)(\= *[A-Za-z0-9_\-\+\.,]+ *)( )(\=\s*[A-Za-z0-9_\-\+\.,]+ *)$/
			)
			|| ( $log_init =~ m/^(.+)(\= *[A-Za-z0-9_\-\+\.,]+ *)( .*)$/ )
		  )
		{
			$log = $1;
			if ( defined($2) ) {
				$val_1 = $2;
				$log .= ' #1 ';
			}
			$log .= $3;
			if ( defined($4) ) {
				$val_2 = $4;
				$log .= ' #2 ';
			}
			$log .= $5;

		}
		else {
			# log fixe
		}
		if ( ( $type eq "I" ) && ( $val_1 eq "" ) ) {
			$log = "[ #1 ]\t" . $log;
		}

# $REQ = "INSERT into log_type(fixe_log) values ('$log')";
# $dbhlog->do($REQ)             or die " Insert en table log_type impossible \n $REQ \n ";
		my $seq_type = 0;
		$log = &conv_to_iso($log);
		if ( exists $log_type{$log} ) {

			$seq_type = $log_type{$log};
			$log_type_nb{$log}++;

		}
		else {
			$seq_type = keys %log_type;
			$seq_type += 1;
			$log_type{$log} = $seq_type;
			$log_type_nb{$log}=1;
		}
		$log =~ s/\'/\'\'/g;

# my @seq_type = $dbhlog->selectrow_array( "select id_type from log_type where fixe_log= '$log';");
		if ( ( $type eq "I" ) && ( $val_1 eq "" ) ) {
			$log = " #1 " . $log;
			$REQ =
"INSERT into log_alim( id_trait ,   type_log ,  texte_log,val1 )  values ($log_seq,'$type',${seq_type},datetime('now'))";

		}
		else {
			$REQ =
"INSERT into log_alim( id_trait ,   type_log ,  texte_log,val1,val2 )  values ($log_seq,'$type',${seq_type},'$val_1','$val_2')";
		}

		if ($log_type_nb{$log} < 50000) {
		$dbhlog->do($REQ)
		  or print STDERR " Insert en table de suivi impossible \n $REQ \n ";
		}

	}
	else {
		print STDOUT "Traces non disponible\n $log \n ";
	}
}

sub usage {
	print "
Aide :
======

Cf documentation avec :
perldoc $0

";
	exit;
}

sub verif_param {
	&usage unless exists $opts{f};
	die
"$0 : impossible de trouver le fichier \"$opts{f}\" passé en paramètre\n\n"
	  unless -f $opts{f};
	my $enc_xml = $opts{e};   # encodage du fichier supposé ligne entete xml...

	$enc_open = ":raw";
	if ( exists $opts{o} ) {
		open( OFILE, ">  $enc_open ", $opts{o} )
		  or die "Impossible d'ouvrir le fichier \"$opts{o}\" en écriture\n\n";
		binmode( OFILE, " $enc_open" );
		select(OFILE);
	}
}

sub ChercheEncodage {
	my $encodage =
	  "";    # cp1252 sous windows mais ne fonctionne pas bien avec car utf8
	         # TODO : Windows7 64bits non géré actuellement
	if ( lc($^O) eq 'mswin32' ) {
		eval {
			#my ($codepage) = ( `chcp` =~ m/:\s+(\d+)/ );
			#$encodage = "cp$codepage";
			$encodage = ":raw";
			foreach my $h ( \*STDOUT, \*STDERR, \*STDIN, ) {
				binmode $h, "$encodage";
			}
		};
	}
	else {
		$encodage = `locale charmap`;
		eval {
			foreach my $h ( \*STDOUT, \*STDERR, \*STDIN, )
			{
				binmode $h, ":encoding($encodage)";
			}
		};
	}
	return $encodage;
}

sub trier_fichier() {
	my $ligne;
	my @elemts;

	# trier sur 3 colonnes
	my ( $fic_in, $ordre_tri ) = @_;
	move( "$fic_in", "${fic_in}_travail" );
	open( FIN,  "< ", "${fic_in}_travail" );
	open( FOUT, "> ", ${fic_in} )
	  or die "Impossible d'ouvrir le fichier ${fic_in}  en écriture\n\n";
	my @rangs = split /\|/, $ordre_tri;
	my @entree = <FIN>;
	$entete = shift(@entree);

#RG:T:Trie de certains format logiciels sage, pour que les écritures soient renumérotées:I

# le fichier en entree est splité par |,
# puis les champs demandés en entrée de fonction ex 0,1,4 sont triés dans l'ordre demandé en format alpha
# les éléments de tableau trié sont join par  | pour reconstituer le fichier initial

	my @sortie = map { join '|', @{$_} } sort {
		     $a->[ $rangs[0] ] cmp $b->[ $rangs[0] ]
		  || $a->[ $rangs[1] ] cmp $b->[ $rangs[1] ]
		  || $a->[ $rangs[2] ] cmp $b->[ $rangs[2] ]
	} map { [ split /\|/, $_ ] } @entree;
	print FOUT $entete;
	print FOUT join( "", @sortie );
	close FOUT;

}

sub modif_acces_direct() {

	# nom fic, taille a lire, expreg  a chercher ,ereg  de substitution
	# retourne 0 : ok, 1 : rien fait, 2 : mal modifié
	my ( $fic, $taille_buf, $er1, $er2 ) = @_;

	open( FT, "+< :raw", $fic ) or die "impossible";

	$nb = sysread FT, $buffer, $taille_buf;
	if ( ( !defined $nb ) || ( $nb == 0 ) ) {
		close FT;
		return 1;
	}

	$buffer =~ s/${er1}/${er2}/;

	if ( length($buffer) != $taille_buf ) { close FT; return 1; }

	sysseek FT, 0, SEEK_SET;

	$nb = syswrite FT, $buffer, $taille_buf;
	close FT;
	if ( ( !defined $nb ) || ( $nb == 0 ) ) {
		return 2;
	}
	return 0;
}

sub parse_xml() {

	my ($fic) = @_;
	$fic = "../client/" . &verif_version_java . "/ressources/" . $fic;

	if ( !-f "$fic" ) {
		&trace( "$fic introuvable" );
		return ( "", "", "" );

	}

	# balise : local ou autre
	my @elements;

	my $parser = XML::Simple->new( KeepRoot => 1 );

	my $doc = $parser->XMLin("$fic");

	my $connect_ldap = "";
	my $db_local     = "";
	my $db_distant   = "";
	my @listeserveurs;

	# Tout le fichier XML est dans $doc sous forme d'arbre

	eval { my $a = @{ $doc->{alto2}->{serveur} }; };
	if ( $@ =~ /^Not an ARRAY reference/ ) {
		push @listeserveurs, $doc->{alto2}->{serveur};
	}
	else {
		@listeserveurs = @{ $doc->{alto2}->{serveur} };
	}

	foreach my $serveur (@listeserveurs) {

		if ( $serveur->{nom} =~ m/local/i ) {
			my $dbase = $serveur->{database};
			$db_local =
			  $dbase->{user} . '|' . $dbase->{password} . '|' . $dbase->{url};

		}
		else {

			my $ldap = $serveur->{ldap};

			$connect_ldap =
			    $ldap->{defautuser} . '@'
			  . $ldap->{domain} . '|'
			  . $ldap->{serverUrl};

			my $dbase = $serveur->{database};
			$db_distant =
			  $dbase->{user} . '|' . $dbase->{password} . '|' . $dbase->{url};
			my $p = Net::Ping->new( 'tcp', 3 );
			my $rc = $p->ping( $dbase->{url} );
			if ( !defined $rc ) {
				&trace(  "Serveur distant non disponible" );

				$db_distant   = "";
				$connect_ldap = "";
			}
			else {
				&trace(  "Serveur distant disponible" );

			}

		}

		#}

	}

	#
	push @elements, $db_local, $db_distant, $connect_ldap;

	return @elements;

}

sub verif_ldap () {
	my ( $passwd, $connexion ) = @_;

	( $user, $url ) = split /\|/, $connexion;

	my $ldap = Net::LDAP->new("$url")
	  or ( &erreur( "I", "connexion ldap impossible" ) && return 0 );

	my $mesg = $ldap->bind( $user, password => "$passwd" );

	#  $mesg = $ldap->bind ( );
	my $rc = $mesg->code;
	if ( $rc eq 0 ) {
		&erreur( "I", "Login ldap correct" );
		return 1;
	}
	else {
		&erreur( "I", "Login ldap incorrect" . $mesg->error_text );
		return 0;
	}

}

sub verif_version_java() {
	if ( &aorte() eq "t") {
	    open(CONF, "< Version_Alto2.txt ") or die "Version_Alto2.txt introuvable dans $currdir";
	    my @temp_version=<CONF>;
	    close CONF;
	    
	    return $temp_version[0];
	    
	}
	
	my @dossiers;
	$dossiers[0] = 0;
	opendir REP, "../client" or ( return 0 );
	@dossiers =
	  sort { sanspoint($b) <=> sanspoint($a) } grep { /^version/ } readdir REP;
	closedir REP;

	return $dossiers[0];

}

sub sanspoint() {
	my ($v) = @_;
	if ( $v =~ m/(\d*)\.(\d*)\.(\d*)/ ) {
		$v = sprintf( "%02d%03d%03d", $1, $2, $3 );
		return $v;
	}
}

# reports fonctions trt_txt :
sub sql_array() {
	($REQ) = shift;

	# en entree un tableau de colonne, en sortie un tableau
	my @result;

	my $ref_dump = $dbh->selectall_arrayref("$REQ")
	  or &erreur( "E", "Echec Requête - $DBI::errstr" . $REQ );
	foreach my $id_ecr (@$ref_dump) {
		@val_ecr = @$id_ecr;
		push @result, join( "\t", @val_ecr );
	}

	return @result;
}

sub sql() {
	($REQ) = shift;

# en entree une ligne  avec 1 ou n colonne, en sortie un tableau contenant les colonnes
	my @result = $dbh->selectrow_array("$REQ")
	  or &erreur( "E", "Echec Requête - $DBI::errstr" . $REQ );
	return @result;
}

sub sql_1col() {
	my ($REQ,$IgnoreFirst) = @_;

# en entree 1 colonne sur n lignes , en sortie tableau contient les valeurs de chaque ligne
	my @result;
	my $ref_result = $dbh->selectall_arrayref("$REQ")
	  or &erreur( "E", "Echec Requête - $DBI::errstr" . $REQ );
	foreach my $id_ecr (@$ref_result) {
		if (defined $IgnoreFirst) {
			shift @$id_ecr;	 
		}
		push @result, join( "|", @$id_ecr );
	}

	return @result;
}

sub  aorte() {
    # a_lim or t_esteur
    my $sourcefile="alto2_alim.pl";
    eval "require \"$sourcefile\" ;" ;
    if ($@) {	return "t";    }
    return "a";
}

sub arrete2013() {
    my ($dc ) = @_;
    if ( substr($dc,0,4) >= 2013 ) { return 1; } else { return 0; }
}


sub detecte_macfile() {
my ($fh) =@_;    
my $buffer;

my $nb= sysread $fh,$buffer, 4096 or return undef;
if ($nb == 0) 			{ return undef;  }
if ($buffer =~ m/\x0D\x0A/) 	{  return "\r\n"; }
elsif ($buffer =~ m/\x0D/) 	{  return "\r";   }
elsif ($buffer =~ m/\x0A/)  	{  return "\n";   }

return undef;

}


1;

