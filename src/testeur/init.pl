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

use Tk;
use Cwd qw ( abs_path );
use Env;
use Config;
use utf8;
no utf8;
use Encode;
use strict;
use File::Basename;
use File::Copy;
use File::Path;
use Archive::Tar;

my $currdir   = dirname( abs_path($0) );
require "$currdir/environnement_alto2.pl";
&Env_Path;
our $ProgramFiles = "$ENV{ProgramFiles}";
our $ProgramData = "$ENV{ProgramData}";


require "$currdir/alto2_fonctions.pl";
require "$currdir/trt_entete.pl";




# logs en base pg
our $dbhlog;
my $dbh;
our $REQ;
our $log_seq;
our $errmsg;

# fin logs
my $OS    = $Config{osname};
my $Archi = $Config{archname};

my $start_dir;
my $alpage;
my $file;
my $xml_file;
my $plat_file;
my $entetefile;
my $line;
my $i;
my $rc;
my $sep        = "";
my $text_alert = "";
my $bic;
my @files;
my $log_file    = "";
my $err_file    = "";
my $siren       = "";
my $datecloture = "";
my $nom_societe;
my $exe_ou_pl = basename($0);
my $dirname   = dirname($0);
my $currdir   = dirname( abs_path($0) );
our $Rep_Alim_ou_Testeur = "alimentation";
my $ctl       = $ARGV[0];
our $Aorte = &aorte();
if ( $Aorte eq "t" ) {
    $Rep_Alim_ou_Testeur = "testeur";
}
#my $workdir   = $currdir . "/temp/";
my $workdir   = $ProgramData . "/${Rep_Alim_ou_Testeur}/temp/";
#my $err_init  = "log/err_" . basename( $0, qw(.exe) ) . "_.log";
my $err_init  = $ProgramData . "/${Rep_Alim_ou_Testeur}/log/err_" . basename( $0, qw(.exe) ) . "_.log";
our $conn_local   = "";
our $conn_distant = "";
our $ldap_distant = "";
my $id        = "";
our $conn_base = "";
# RG:T:$mot_passe ne doit pas être défini, testé plus tard dans le code /!\ 
our $mot_passe ;
our $serveur_choisi = "";
open( IF, "> $err_init" );
close IF;    # creation vide , ensuite trace en ajout...

if ( $Aorte ne "t" ) {
    # parsing xml config
    ( $conn_local, $conn_distant, $ldap_distant ) = &parse_xml("alto2.xml");
}
  
# print STDERR "$conn_local, $conn_distant, $ldap_distant";
$serveur_choisi = $conn_local;

my $tar;
if ( $exe_ou_pl !~ m/\./ ) {
    $exe_ou_pl = ".exe";
}
else {
    $exe_ou_pl =~ s/^.*(\..+)$/$1/;
}

if ( ${OS} =~ m/linux/i ) {
    $start_dir = "./";
}
else {
    # todo : remplacer par dirname ?

#    $workdir = "${currdir}/temp/";
#    $start_dir = substr( "${currdir}", 0, 2 );
    $workdir = "${ProgramData}/${Rep_Alim_ou_Testeur}/temp/";
    $start_dir = substr( "${currdir}", 0, 2 );
}
if ( !-d $workdir ) {
    mkdir($workdir);
}

if ( !defined $ctl ) {
    $ctl = "IMP";
}
my $fen = MainWindow->new();
$fen->geometry("360x380+20+20");

if ( $Aorte eq "t" ) {
    $fen->title( &utf8toutf8("Test de Compta Démat") );
}
else {
    if ( lc($ctl) eq "ctl" ) {
        $fen->title( &utf8toutf8("Alto2 - Contrôle") );
    }
    else {
        $fen->title("Alto2 - Alimentation");
    }
}
my $fen1   = $fen->Frame;
my $label1 = $fen1->Label(
    -text => &utf8toutf8("Entrer le numéro alpage\n du dossier :") )
  ->pack( -side => 'left' );
my $entree =
  $fen1->Entry( -textvariable => \$alpage, -background => 'cyan' )
  ->pack( -side => 'right' );
$fen1->pack( -side => 'top', -pady => '5' );
my $fen_nom = $fen->Frame;
my $label2  = $fen_nom->Label(
    -text => &utf8toutf8("Entrer le nom de           \nla société :") )
  ->pack( -side => 'left' );
my $entree2 =
  $fen_nom->Entry( -textvariable => \$nom_societe, -background => 'cyan' )
  ->pack( -side => 'right' );
$fen_nom->pack( -side => 'top', -pady => '5' );

my $pcg;
my $fen3   = $fen->Frame->pack();
my $fen3g  = $fen3->Frame->pack( -side => 'left' );
my $fen3d  = $fen3->Frame->pack( -side => 'right' );
my $lbl_pc = $fen3g->Label( -text => "Type de plan comptable " )->pack();
my @lst_pc = (
    &utf8toutf8('PCGénéral'),
    "PC assurance \net capitalisation",
    &utf8toutf8("PC établissements \nde crédit"),
    &utf8toutf8("PC établissements \nd'investissement")
);
my @lst_code = ( 'PCG', 'PCPAC', 'PCEC', 'PCEI' );
my @lbl_r;

for ( $i = 0 ; $i <= $#lst_pc ; $i++ ) {
    $lbl_r[$i] = $fen3g->Radiobutton(
        -text     => $lst_pc[$i],
        -value    => $lst_code[$i],
        -variable => \$pcg,
        -anchor   => 'w'
    )->pack( -side => "top", -anchor => 'w' );
}
$lbl_r[0]->select();

my $lbl_pc_1 = $fen3d->Label( -text => "Type de revenus " )->pack();
my @lst_rev = (
    'BIC/IS',
    "BNC ou BA\n Droit commercial",
    &utf8toutf8("BA, \nTrésorerie"),
    &utf8toutf8("BNC \nTrésorerie")
);
my @lst_coderev = ( 'BIC', 'COM', 'BAT', 'BNCT' );
my @lbl_rb;
for ( $i = 0 ; $i <= $#lst_rev ; $i++ ) {
    $lbl_rb[$i] = $fen3d->Radiobutton(
        -text     => $lst_rev[$i],
        -value    => $lst_coderev[$i],
        -variable => \$bic,
        -anchor   => 'w'
    )->pack( -side => "top", -anchor => 'w' );
}
$lbl_rb[0]->select();

# ACCES LOCAL/DISTANT
my $butlocal;
my $butdistant;
my $fen4;
my $entree3;
if ( $conn_distant ne "" ) {
    my @list_dist = split /\@/, $ldap_distant;
    $id = $list_dist[0];
    $fen4 = $fen->Frame->pack( -side => 'top', -pady => '5' );
    my $fen41 = $fen4->Frame->pack( -side => 'left',  -pady => '5' );
    my $fen42 = $fen4->Frame->pack( -side => 'right', -pady => '5' );

    $butlocal = $fen41->Button(
        -text    => "Portable",
        -command => \&choix_serveur,
        -relief  => 'sunken'
    )->pack( -side => 'left' );
    $butdistant = $fen41->Button(
        -text    => "Serveur",
        -command => \&choix_serveur,
        -relief  => 'raised'
    )->pack( -side => 'left' );

    my $label7 =
      $fen42->Label( -text => &utf8toutf8( "identifiant :  " . $id ) )
      ->pack( -side => 'top' );
    my $label6 =
      $fen42->Label( -text => &utf8toutf8("mot passe :") )
      ->pack( -side => 'left' );
    $entree3 = $fen42->Entry(
        -textvariable => \$mot_passe,
        -background   => 'cyan',
        -show         => '*',
        -state        => 'disabled'
    )->pack( -side => 'right' );

}

my $fen2 = $fen->Frame;

my $alerte =
  $fen2->Label( -textvariable => \$text_alert, -foreground => 'red' )->pack();
my $Button1 = $fen2->Button(
    -text    => &utf8toutf8('Selectionner un fichier à traiter'),
    -command => \&traitement
)->pack();

$fen2->pack( -side => 'bottom' );

sub traitement() {
    $text_alert = "";
    my $fille;
    $conn_base = $conn_local;
    if ( ( &aorte() ne "t" ) and ( defined $mot_passe ) ) {
        if ( &verif_ldap( $mot_passe, $ldap_distant ) ) {
            $conn_base = $conn_distant;
            $entree3->configure( -background => 'cyan' );
            $fen->update;
        }
        else {
            $entree3->configure( -background => 'red' );
            $text_alert .= &utf8toutf8(
                " Le mot de passe est incorrect pour cet identifiant ");

            $fen->update;
            return;
        }
    }
    $fille = MainWindow->new();
    $fille->geometry("150x50+420+0");
    $fille->title("Fichier :");
    $fille->Label( -text => "\nVeuillez patientez svp...\n\n" )->pack();

    # Modif pour compatibilite Windows/Linux
    #    my @af_files =
    my $af_files =
      $fille->getOpenFile( -initialdir => $start_dir, -multiple => 1 );

    #RG:F:Numéro alpage saisi au format a-z, A-Z, 0-9 ou - :E
    if ( $alpage eq "" || $alpage !~ /^[a-zA-Z0-9-]*$/ ) {
        $text_alert .= &utf8toutf8(" Le numéro au format alpage est requis ");
        $entree->configure( -background => 'red' );
        undef @files;
        undef $af_files;
        $fille->destroy() if defined $fille;
        $fen->update;
    }
    else {
        #RG:T:Remplacement du - par _ dans le numéro alpage :I
        $alpage =~ s/-/_/g;
        $alpage = lc($alpage);
        $entree->configure( -background => 'cyan' );
        $fen->update;
    }

    #RG:T:Traitement des accents dans le nom du fichier

    #spec 02-2014  : nom société quote doublée
    $nom_societe =~ s/\'/\'\'/g;

    # Modif pour compatibilite Windows/Linux
    #    foreach my $file1 (@af_files) {
    foreach my $file1 ( @{$af_files} ) {
        if ( ${OS} !~ m/linux/i ) {
            $file1 = encode( 'iso-8859-1', $file1 );
        }
        my $filename      = basename($file1);
        my $copie_a_faire = 1;
        if ( -f $workdir . $filename ) {
            my $taille1 = ( stat("$file1") )[7];
            my $taille2 = ( stat( $workdir . $filename ) )[7];
            if ( $taille1 == $taille2 && $taille1 > 1000000 ) {
                $copie_a_faire = 0;
            }

        }

        copy( $file1, $workdir . $filename ) if ( $copie_a_faire == 1 );
        $file = $workdir . $filename;
        push( @files, $file );
    }

    #RG:T:Traitement anciens formats
    if ( &aorte eq "a" ) {

        if (
            ( uc($file) =~ m/(.*)\.TRA$/ )
            || (   uc($file) =~ m/(.*)\.TXT$/
                && uc($file) !~
                m/^.*\/(.*)FEC(20[0-9]{2}[0-1][0-9][0-3][0-9])/ )
            || ( uc($file) =~ m/(.*)\.DBF$/ )
          )
        {
            if ( $#files > 1 ) {
                $text_alert .= &utf8toutf8(
" Les anciens formats doivent être sélectionnés un par un \n"
                );
                $fen->update;
                return;
            }

            #RG:T:Traitement spécifique pour les anciens formats ebp... :I
            &init_dossier or die "Probleme d'accès à Postgres";
            my $curdir = dirname( @{$af_files}[0] );
            $err_file = "${ProgramData}" . "/${Rep_Alim_ou_Testeur}/log/err_" . basename( ${file} ) . "_AF.log";
            $rc =
`trt_old_format_cpta$exe_ou_pl -f \"$file\" -n $log_seq -t \"$exe_ou_pl\" -c \"$curdir\" 2> \"${err_file}\"`;
            if ( $rc eq "Abort" ) {
                $text_alert .= &utf8toutf8(
" Problème dans le traitement de l'ancien format de compta\n Veuillez analyser les logs\n"
                );
                $fen->update;
                return;
            }
            else {
                undef @files;
                push( @files, $rc );
                $file = $files[0];
            }
        }

        # RG:T:Traitement fichiers access mdb
        if ( lc($file) =~ m/(.*)\.mdb$/ ) {
            if ( $#files > 1 ) {
                $text_alert .= &utf8toutf8(
" Les fichiers access doivent être séléctionnés un par un \n"
                );
                $fen->update;
                return;
            }
            $err_file = "${ProgramData}" . "/${Rep_Alim_ou_Testeur}/log/err_" . basename( ${file} ) . "_access.log";
            &init_dossier or die "Probleme d'accès à Postgres";
            $rc =
`trt_mdb$exe_ou_pl   -f \"$file\"  -l \"${err_file}_mdb\" -n $log_seq 2> \"${err_file}_mdb\"`;
            @files = split /;/, $rc;
        }
    }
    if ( $text_alert ne "" ) { return; }
    foreach my $file1 (@files) {
        $file       = $file1;
        $entetefile = $file;
        $plat_file  = $file;
        $entetefile =~ s/$/.entete/;
        uc($file)   =~ m/^.*\/(.*)FEC(20[0-9]{2}[0-1][0-9][0-3][0-9])/;
        $siren       = $1;
        $datecloture = $2;

#RG:T:Vérification que le nom du fichier en entree correspond à l'attendu de l'arrêté :E

        if ( ( $siren eq "" ) || ( $datecloture eq "" ) ) {
            $text_alert .= &utf8toutf8(
"\n Le nom du fichier $file  est incorrect \n  attendu sirenFECAAAAMMJJ  \n re-essayez en ne sélectionnant qu'un fichier'"
            );
            $fille->destroy() if defined $fille;
            undef @files;
            $fen->update;

            return;
        }
        $log_file = "${ProgramData}" . "/${Rep_Alim_ou_Testeur}/log/log_${siren}_$datecloture.log";
        $err_file = "${ProgramData}" . "/${Rep_Alim_ou_Testeur}/log/err_${siren}_$datecloture.log";

        &init_dossier or die "Probleme d'accès à Postgres";

        open( my $hf, "<", "$file" )
          or &trace( "Impossible de trouver $file", "finko" );
        my $crlf = &detecte_macfile($hf);
        close $hf;

        open( F, "< $file" )
          or &trace( "Impossible de trouver $file", "finko" );
        binmode F, ":raw";
        local $/ = $crlf;

        my $pref_chem = "";
        if ( ${OS} =~ m/linux/i ) {
		#$pref_chem = "./";
		$pref_chem = "$currdir/";
	}
	
        while ( $line = <F> ) { last; }
        close F;

        $line =~ s/\r\n|\r$//;
        $line =~ s/\c@//g;

        chomp $line;
	if ( $line =~ m/^<\?xml/i || $line =~ m/^...<\?xml/i )
	{    # traitement xml_file
                # <?xml  précédé d'un BOM éventuel
             #RG:T: Si la première ligne du fichier est au format xml, conversion en fichier texte:I
            $line =~ s/.*encoding="(.*)"\?>/$1/;

            # chdir "$dirname" ;
            # copie des format xsd arrêté
            # print STDERR cwd();
	    if ( $line =~ /ISO-8859-15/ ) {
                    my $cont_iso =
                      &modif_acces_direct( $file, 80, 'ISO-8859-15"',
                        'ISO-8859-1" ' );
                    if ( $cont_iso == 2 ) {
                        &trace( "Problème sur la gestion de l'encodage xml",
                            "finko" );
                    }

            }
            elsif ( $line =~ /iso-8859-15/ ) {
                    my $cont_iso =
                      &modif_acces_direct( $file, 80, 'iso-8859-15"',
                        'iso-8859-1" ' );
                    if ( $cont_iso == 2 ) {
                        &trace( "Problème sur la gestion de l'encodage xml",
                            "finko" );
                    }
            }
		
#            if ( ${OS} !~ m/linux/i ) {
                
	    my $cont_xsd = &modif_acces_direct(
		    $file, 300,
		    'xsi:noNamespaceSchemaLocation="file:formatA47A',
		    '     xsi:noNamespaceSchemaLocation="formatA47A'
	    );
	    if ( $cont_xsd == 2 ) {
		    &trace( "Problème sur la gestion du lien file xsd",
		    "finko" );
	    }
	    elsif ( $cont_xsd == 3 ) {
		    &faire_pdf(
    "Le fichier XML ne respecte pas les spécifications publiés sur le site impots.gouv.fr, relatives à la structure du fichier XSD."
		    );
		    exit 1;
	    }

	    chdir "${ProgramData}/${Rep_Alim_ou_Testeur}";
	    $tar = Archive::Tar->new("formats_xsd.tar");
	    &trace( $tar->error, "finko" ) unless $tar->extract;
	    chdir "${ProgramFiles}/${Rep_Alim_ou_Testeur}";
	    
	    my $xmllintpath = "";
	    if ( ${OS} !~ m/linux/i ) {
		if ( -d "${ProgramFiles}/xmllint_x86_64" ) {
			$xmllintpath = "${ProgramFiles}/xmllint_x86_64/";
		    } else {
# 		    	$tar = Archive::Tar->new("xmllint.tar");
# 			&trace( $tar->error, "finko" ) unless $tar->extract;
# 			if ( $Archi =~ /win32-x64/i ) {
# 				$xmllintpath = "${currdir}/xmllint_x86_64/";
# 			    } else {
# 				if ( $Archi =~ /win32/i ) {
# 					$xmllintpath = "${currdir}/xmllint_x86/";
# 				} else {
# 					$xmllintpath = "${currdir}/xmllint_AMD64/";
# 				}
# 			}
			$xmllintpath = "${ProgramFiles}/xmllint_x86/";
		}
	    }
	    
            my $rc2 = 0;    
#             if ( ${OS} !~ m/linux/i ) {
# 
#                 # $? retourne  0 ok, ou 1 ko , le $rc est mis en base
#                 # if ($ctl ne "NOX" ) {
#                 $rc = `StdInParse.exe -n -f -s -v=always < \"$file\"   2>&1 `;
# 
#                 # }
#                 #else {
#                 #	$ctl='CTL';
#                 #	$rc="";
#                 #}
#                 $rc2 = $?;
# 	    }
# 	    else {
		my $read_buffer = "";
		open( FT, "+< :raw", $file ) or die "impossible";

		my $read_nb = 0;
		$read_nb = sysread FT, $read_buffer, 300;
		close FT;
		if ( $read_buffer =~ m/noNamespaceSchemaLocation(.*)=(.*)"(.*).xsd"(.*)/i ) {
			my $xsdfile = $3 . ".xsd";
			$xsdfile =~ s/file://;
			$xsdfile = "${ProgramData}/${Rep_Alim_ou_Testeur}/${xsdfile}";
			$rc = `\"${xmllintpath}xmllint\" --noout \"$file\" --schema \"$xsdfile\" 2>&1 `;
			$rc2 = $?;
		} else {
			$rc2 = 1;
		}
#	    }
		if ( $rc2 ne 0 ) {

			# erreur
			$text_alert .= &utf8toutf8(
	"Format de fichier  non pris en charge  \n Fichier xml non conforme au xsd "
			);
			
			&trace( "Pb au parseur xml : $rc ", "" );
			$fille->destroy() if defined $fille;
			undef @files;
			$fen->update;

			# fiche 14
			&faire_pdf(
	"Le fichier XML ne respecte pas les spécifications publiés sur le site impots.gouv.fr, relatives à la structure du fichier XSD."
			);
			exit 1;

			# return;
		}
		my $xmllint_dir = "${currdir}/xmllint_x86";
		rmtree(${xmllint_dir});
		$xmllint_dir = "${currdir}/xmllint_x86_64";
		rmtree(${xmllint_dir});
		$xmllint_dir = "${currdir}/xmllint_AMD64";
		rmtree(${xmllint_dir});
		unlink <format*xsd>;
	#	}
		$xml_file = $file;
		$file =~ s/[\.xml]*$/.dat/i;

		$rc = system(
	"${pref_chem}trt_xml$exe_ou_pl   -o \"$file\"  -f  \"$xml_file\"  -T EXERCICE  -t JOURNAL  -n $log_seq -e \"$line\" 2>${err_file}_xml"
		);    # ajouter -d  pour activer les traces sur xml
        if ( $rc > 0 ) {
            print STDERR
	        "\"${pref_chem}trt_xml$exe_ou_pl\" -o \"$file\" -f \"$xml_file\" -T EXERCICE -t JOURNAL -n $log_seq -e \"$line\" 2> \"${err_file}_xml\""
            ;
            &finko("${err_file}_xml");
            exit 1;
        }  #>$log_file 2>$err_file ");
	}         # fin traitement xml_file
        else {    # traitement plat
             #RG:T:recherche du séparateur dans le fichier  tab ou | traitement spécifique:I
             # détection type fichier
	     #RG:F:fiche 16 : à compter 1/1/2013 vir et pvi interdits
            my @comp_tab = split /\t/, $line;
            my @comp_pip = split /\|/, $line;
            my @comp_pvi = split /;/,  $line;
            my @comp_vir = split /,/,  $line;
            if    ( $#comp_tab >= 8 ) { $sep = "T"; }
            elsif ( $#comp_pip >= 8 ) { $sep = "P"; }
            elsif ( ( not &arrete2013($datecloture) ) and $#comp_vir >= 8 ) {
                $sep = "V";
            }
            elsif ( ( not &arrete2013($datecloture) ) and $#comp_pvi >= 8 ) {
                $sep = "PV";
            }
            else {
                $text_alert .= &utf8toutf8(
"Format de fichier non conforme.\n Séparateur dans le fichier non conforme"
                );
                $fen->update;
                return;
            }
	    

#RG:F:transformation entete champs arrete => champs base:I
#$rc = system("trt_entete$exe_ou_pl   -o \"$entetefile\"  -f  \"$plat_file\"  -s \"$sep\" -n $log_seq 2>${err_file}_entete"            );
            $rc = &sub_entete( "$entetefile", "$plat_file", "$sep", $log_seq );
            if ( $rc > 0 ) {
		&trace( "$errmsg", "finko" );
                #&finko("${err_file}_entete");
            }
            $rc = system(
"${pref_chem}trt_txt$exe_ou_pl  \"$file\" $sep $siren $alpage $datecloture $err_file  $pcg $bic  \"$nom_societe\" \"$ctl\" $log_seq  \"$conn_base\" \"$id\" "
            );    #>$log_file 2>$err_file ");
            if ( $rc > 0 ) {
                print STDERR
"${pref_chem}trt_txt$exe_ou_pl  \"$file\" $sep $siren $alpage $datecloture $err_file  $pcg $bic  \"$nom_societe\" \"$ctl\" $log_seq   \"$conn_base\" \"$id\" "
                  ;    # &finko("${err_file}";
                exit 1;
            } 
        }    # fin traitement plat
    }    # fin foreach
    &fin();
}    # fin sub traitement

sub choix_serveur () {
    if ( $serveur_choisi eq $conn_local ) {
        $butlocal->configure( -relief => 'raised' );
        $butdistant->configure( -relief => 'sunken' );
        $serveur_choisi = $conn_distant;
        $entree3->configure( -state => 'normal' );

    }
    else {
        $serveur_choisi = $conn_local;
        $butlocal->configure( -relief => 'sunken' );
        $butdistant->configure( -relief => 'raised' );
        $entree3->configure( -state => 'disabled' );

    }
    $fen4->update();

}

sub finko () {
    my ($log_temp) = @_;
    print STDERR "Sortie KO";
    close IF;
    if ( ${OS} =~ m/linux/i ) {
        exec("gedit ${log_temp}");
    }
    else {
        #exec("start wordpad \"${log_temp}\"");
        exec("start notepad \"${log_temp}\" ");
    }

    exit 1;
}

sub fin () {

    #todo : chemin variable
    my $workdir = "${ProgramData}/${Rep_Alim_ou_Testeur}/temp";
    if ( ${OS} =~ m/linux/i ) {
        $workdir = "${ProgramData}/${Rep_Alim_ou_Testeur}/temp";
        rmtree($workdir);
    }
    else {
        rmtree($workdir);
    }
    close IF;
    exit 0;
}

sub trace() {

    my ( $log_trace, $fin ) = @_;
    open( IF, ">> $err_init" );
    print IF "$log_trace";
    close IF;
    if ( $fin eq "finko" ) {
        &finko("${err_init}");
    }
}

sub init_dossier() {

    # Mise en place base sqlite pour les traces en vue d'être plus portable

    # ouverture des logs
    # si $dblogname n'existe pas, création du fichier vide automatiquement
    $dbhlog = &connexion_log( "altoweb2", $dbh, "nocreate" );

# --heure_etape TEXT DEFAULT (strftime('%Y-%m-%d %H:%M:%S','now', 'localtime')),

    $dbhlog->do(
        "CREATE TABLE  if not exists log_alim
( id_trait INT ,
  id_ligne INTEGER PRIMARY KEY AUTOINCREMENT,
  type_log TEXT,
  texte_log INTEGER,
  val1 text,
  val2 text
)"
    ) or &trace( $DBI::errstr, 'finko' );

    #unique on conflict ignore
    $dbhlog->do(
        "CREATE TABLE  if not exists log_type
( id_type INTEGER   ,
  fixe_log text   unique on conflict ignore
)  "
    ) or &trace( $DBI::errstr, 'finko' );

    $dbhlog->do(
        "CREATE TABLE if not exists suivi_alim 
( id_trait INTEGER PRIMARY KEY AUTOINCREMENT,
  num_alpage text,
  nom_fichier text,
  date_cloture text,
  heure_etape text DEFAULT (strftime('%Y-%m-%d %H:%M:%S','now', 'localtime')),
  db_cree boolean
)"
    ) or &trace( $DBI::errstr, 'finko' );

    $REQ =
"INSERT into suivi_alim ( num_alpage ,  nom_fichier,  date_cloture ,    db_cree )
values ('$alpage','$file','$datecloture',0);";
    $dbhlog->do($REQ)
      or &trace( " Insert en table de suivi impossible", 'finko' );
    $log_seq = &recup_noseq;
    $REQ     = "INSERT into log_type (id_type,fixe_log) values (1,'init');";

    $dbhlog->do($REQ)
      or &trace( " Insert en table fixe_log impossible", 'finko' );
}

sub faire_pdf() {
    my ($texte_erreur) = @_;
    require "$currdir/alto2_pdf.pl";

    use utf8;
    my $text_to_place ;
    if ( &aorte() ne "t" ) {
	
	$text_to_place = "  ANNEXE\n";
    }
    $text_to_place .= " CONTROLE DE LA STRUCTURE DU FEC

(Conformément aux dispositions prévues à l'article A.47 A-1\n du livre des procédures fiscales)";
	
    
    our $font_size = 13;
    our $align     = "center";
    my @result;
    my $vers_java=&verif_version_java();
    chomp $vers_java;
    my $rResult = \@result;

    &ombre( $text_to_place, 185, 80 );
    $align     = "center";
    $font_size = 11;
    $dbh       = $dbhlog;
    $text_to_place ="Concerne le SIREN : $siren ,  Exercice clos le : $datecloture, Version : $vers_java "      ;
    &ombre( $text_to_place, 190, 50 );
    $align = "left";

    # Champs oblig manquant

    $text_to_place =
" La structure du fichier des écritures comptables remis ne peut être considérée comme conforme aux dispositions de l’article A.47 A-1 du Livre des Procédures Fiscales pour les raisons ci-dessous :";

    &ajoute_paragraphe( $text_to_place, 180, 75 );

    # ajoute le message d'erreur :
    &ajoute_paragraphe( &utf8toutf8($texte_erreur), 180, 75 );

    
    &ajoute_paragraphe("La conformité structurelle du FEC ne présage pas de la régularité de la comptabilité, \nni de sa valeur probante.",
        180, 50    );
    
    
    if ( &aorte() eq "t" ) {
    &ajoute_paragraphe("Ce test a été effectué avec l'application Test Compta Démat version $vers_java. La synthèse des résultats ne constitue pas une attestation de conformité, elle ne saurait engager l'administration.",180,50);
    }
    my ( $sec, $min, $hour, $mday, $mon, $year ) = localtime(time);
    my $nouv_pdf =  "${ProgramData}" . '/rapports/rapport_' . basename($file) . "_$hour$min$sec" . '.pdf';

    &sauve_pdf($nouv_pdf);

    if ( ${OS} =~ m/linux/i ) {
#        system("evince $nouv_pdf");
        system("xdg-open $nouv_pdf 2> /dev/null");
    }
    else {
        system("start $nouv_pdf");
    }
}

sub Tk::Error {
    my ( $Widget, $Error, @Locations ) = @_;
    &trace( "Erreur system : contacter l' AT : " . $Error, 'finko' );

}

MainLoop;
