-- attention syntaxe :  
-- fichier lu à 3 endroits dans le code source, syntaxe strict obligatoire

DROP TABLE IF EXISTS fec_<cloture>  CASCADE;
DROP INDEX IF EXISTS  idx_cpt_date_fec_<cloture> ;
DROP INDEX IF EXISTS idx_date_num_ecr_fec_<cloture>;
DROP INDEX IF EXISTS idx_num_ecr_fec_<cloture>;
DROP INDEX IF EXISTS idx_cpt_aux_fec_<cloture>;
DROP INDEX IF EXISTS idx_jrn_fec_<cloture>;
DROP INDEX IF EXISTS idx_piece_fec_<cloture>;
-- DROP INDEX IF EXISTS idx_debit_fec_<cloture>;
-- DROP INDEX IF EXISTS idx_credit_fec_<cloture>;
DROP INDEX IF EXISTS idx_cpt_debit_fec_<cloture>;
DROP INDEX IF EXISTS idx_cpt_credit_fec_<cloture>; 

   -- lib_jrnal text default 'inconnu', 

CREATE TABLE fec_<cloture> ( -- La clôture est au format AAAAMMJJ
	id_ligne serial NOT NULL , -- Numéro généré par le système
	code_jrnal text DEFAULT '' , -- Champ "JournalCode" de l'arrêté      																							  CF1:OBLIGATOIRE
	lib_jrnal text  DEFAULT '' , -- Champ "JournalLib" de l'arrêté
	num_ecr text NOT NULL , -- Champ "EcritureNum" de l'arrêté (Champ Obligatoire)
	date_cpt date NOT NULL , -- Champ "EcritureDate" de l'arrêté (Champ Obligatoire)
	num_cpte_gen text NOT NULL , -- Champ "CompteNum" de l'arrêté (Champ Obligatoire, les 3 premiers caractères doivent être numériques)
	lib_cpte_gen text , -- Champ "CompteLib" de l'arrêté
	num_cpt_aux text DEFAULT '' , -- Champ "CompteAuxNum" de l'arrêté
	lib_cpt_aux text DEFAULT '' , -- Champ "CompteAuxLib" de l'arrêté
	num_piece text DEFAULT '' , -- Champ "PièceRef" de l'arrêté
	date_piece date , -- Champ "PièceDate" de l'arrêté
	lib_ecriture text DEFAULT '', -- Champ "EcritureLib" de l'arrêté																									CF1:OBLIGATOIRE
	mtn_debit numeric NOT NULL , -- Champ "Debit" de l'arrêté (Champ Obligatoire)
	mtn_credit numeric NOT NULL , -- Champ "Credit" de l'arrêté (Champ Obligatoire)
	ecr_type int DEFAULT 0  , -- Champ "Résultat" de l'arrêté. Ce champ vaut 1 si c'est une écriture de résultat et 0 sinon.
	code_lettrage text , -- Champ "EcritureLet" de l'arrêté
	date_lettrage date , 
	valid_date date ,  -- Champ ValidDate " de l'arrêté      																												 CF1:OBLIGATOIRE
	idevise  text DEFAULT '',  --Champ idevise arrêté
	mtn_devise numeric ,  --Champ montantdevise arrêté
	--paiement_date date, -- Champ "DatePaiemt"
	--paiement_mode text DEFAULT '', -- Champ "ModePaiemt"
	--prestation text DEFAULT '', -- Champ "Natpresta" ou "NatOp"
	--client text DEFAULT '', -- Champ "Client"
	<champs_complementaires>
	tva_type text DEFAULT '', -- champs calculé
	alto2_taux_tva numeric DEFAULT 0 , -- champs calculé
	CONSTRAINT pk_fec_<cloture> PRIMARY KEY (id_ligne)
	);
	
 

