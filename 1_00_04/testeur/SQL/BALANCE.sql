DROP TABLE IF EXISTS  balance_<cloture> CASCADE;

commit ;

-- Tables balance
CREATE TABLE balance_<cloture> (
id_balance serial NOT NULL,
ecr_cte_lig_gen_lib text ,    
ecr_cte_lig_gen_nid text NOT NULL,
num_cpt_aux text,              
      lib_cpt_aux text, -- Ligne ajoutée
sld_an_deb numeric,                    
sld_an_cre numeric,
mass_av_clo_deb numeric NOT NULL,    
mass_av_clo_cre numeric NOT NULL,
mass_ap_clo_deb numeric NOT NULL,    
mass_ap_clo_cre numeric NOT NULL,
sld_av_clo_mtn_deb numeric NOT NULL,    
sld_av_clo_mtn_cre numeric NOT NULL,
sld_ap_clo_mtn_deb numeric NOT NULL,  
  sld_ap_clo_mtn_cre numeric NOT NULL,
nbr_lign integer NOT NULL,     
       avr_lign_ecr numeric NOT NULL,
max_lign numeric NOT NULL,
CONSTRAINT pk_balance_<cloture> PRIMARY KEY (id_balance)) ; 
commit ;

-- Insertion des données dans la table balance
INSERT INTO balance_<cloture> (
ecr_cte_lig_gen_nid, ecr_cte_lig_gen_lib, num_cpt_aux, lib_cpt_aux, sld_an_deb, sld_an_cre, mass_av_clo_deb,
mass_av_clo_cre, mass_ap_clo_deb, mass_ap_clo_cre, sld_av_clo_mtn_deb, sld_av_clo_mtn_cre, sld_ap_clo_mtn_deb,
sld_ap_clo_mtn_cre, nbr_lign, avr_lign_ecr, max_lign) (

	SELECT num_cpte_gen, lib_cpte_gen, num_cpt_aux, lib_cpt_aux,

	-- Débit et crédit AN
	sum(CASE WHEN ((ecr_type = 2) OR (ecr_type = 12)) THEN mtn_debit ELSE 0.0 END),
	sum(CASE WHEN ((ecr_type = 2) OR (ecr_type = 12)) THEN mtn_credit ELSE 0.0 END),

	-- Masse débit et crédit avant Cloture
	sum(CASE WHEN ((ecr_type != 1) AND (ecr_type != 11)) THEN mtn_debit ELSE 0.0 END),
	sum(CASE WHEN ((ecr_type != 1) AND (ecr_type != 11)) THEN mtn_credit ELSE 0.0 END),

	-- Masse débit et crédit après Cloture
	sum(mtn_debit), sum(mtn_credit),

	-- Solde débit avant cloture
	CASE WHEN sum(CASE WHEN ((ecr_type != 1) AND (ecr_type != 11)) THEN mtn_debit ELSE 0.0 END) > sum(CASE WHEN ((ecr_type != 1) AND (ecr_type != 11)) THEN mtn_credit ELSE 0.0 END) THEN
	sum(CASE WHEN ((ecr_type != 1) AND (ecr_type != 11)) THEN mtn_debit ELSE 0.0 END) - sum(CASE WHEN ((ecr_type != 1) AND (ecr_type != 11)) THEN mtn_credit ELSE 0.0 END) ELSE 0.0 END,

	-- Solde crédit avant cloture
	CASE WHEN sum(CASE WHEN ((ecr_type != 1) AND (ecr_type != 11)) THEN mtn_debit ELSE 0.0 END) < sum(CASE WHEN ((ecr_type != 1) AND (ecr_type != 11)) THEN mtn_credit ELSE 0.0 END) THEN
	sum(CASE WHEN ((ecr_type != 1) AND (ecr_type != 11)) THEN mtn_credit ELSE 0.0 END) - sum(CASE WHEN ((ecr_type != 1) AND (ecr_type != 11)) THEN mtn_debit ELSE 0.0 END) ELSE 0.0 END,

	-- Solde débit après cloture
	CASE WHEN sum(mtn_debit) > sum(mtn_credit) THEN sum(mtn_debit) - sum(mtn_credit) ELSE 0.0 END,

	-- Solde crédit après cloture
	CASE WHEN sum(mtn_debit) < sum(mtn_credit) THEN sum(mtn_credit) - sum(mtn_debit) ELSE 0.0 END, --COUNT(*),

	-- Count sauf écritures générées
	sum(CASE WHEN ((ecr_type != 11) AND (ecr_type != 12)) THEN 1 ELSE 0 END), 

	-- Moyenne hors écritures générées
	CASE WHEN (avg(CASE WHEN ((ecr_type != 11) AND (ecr_type != 12)) THEN mtn_debit+mtn_credit ELSE NULL END)) IS NULL THEN 0.0 ELSE 
	avg(CASE WHEN ((ecr_type != 11) AND (ecr_type != 12)) THEN mtn_debit+mtn_credit ELSE NULL END) END, 

	-- Maximum hors écritures générées
	GREATEST(max(CASE WHEN ((ecr_type != 11) AND (ecr_type != 12)) THEN mtn_debit ELSE 0.0 END), max(CASE WHEN ((ecr_type != 11) AND (ecr_type != 12)) THEN mtn_credit ELSE 0.0 END)) 

	FROM fec_<cloture> 
	GROUP BY num_cpte_gen, lib_cpte_gen, num_cpt_aux, lib_cpt_aux);

commit ;


-- Mise en place des listes 

DROP TABLE IF EXISTS listcompte_<cloture> ;
DROP TABLE IF EXISTS listcptaux_<cloture>;
DROP TABLE IF EXISTS listdatecomptable_<cloture>;
DROP TABLE IF EXISTS listdatelettrage_<cloture>;
DROP TABLE IF EXISTS listdatepiece_<cloture>;
DROP TABLE IF EXISTS listdatevalidation_<cloture>;
DROP TABLE IF EXISTS listjournal_<cloture> ;
DROP TABLE IF EXISTS listcomptegenaux_<cloture> ;
DROP TABLE IF EXISTS listdevise_<cloture> ;
DROP TABLE IF EXISTS listtxtva_<cloture>;
 -- Tables list... qui permettent d'accélérer l'affichage
 commit ;

CREATE TABLE listcompte_<cloture> (num_cpte_gen  , lib_cpte_gen  ) 
AS
( SELECT LTRIM(ecr_cte_lig_gen_nid, '0'),  ecr_cte_lig_gen_lib
FROM  balance_<cloture>
GROUP BY ecr_cte_lig_gen_nid, ecr_cte_lig_gen_lib );

 commit ;


CREATE TABLE listcptaux_<cloture> (num_cpt_aux  , lib_cpt_aux )
AS 
(SELECT num_cpt_aux , lib_cpt_aux 
FROM  balance_<cloture>
WHERE num_cpt_aux IS NOT NULL 
AND lib_cpt_aux   IS NOT NULL 
AND ( num_cpt_aux != '' 
	OR  lib_cpt_aux!= '') 
GROUP BY num_cpt_aux ,lib_cpt_aux  
ORDER BY num_cpt_aux ,lib_cpt_aux  );
commit ;

CREATE TABLE listdatecomptable_<cloture> (date_cpt ) AS
( SELECT distinct(date_cpt) FROM fec_<cloture>  ORDER BY date_cpt );
commit ;

CREATE TABLE listdatelettrage_<cloture> (date_lettrage  )
AS 
( SELECT distinct(date_lettrage)
	FROM fec_<cloture> 
	WHERE date_lettrage IS NOT NULL 
	GROUP BY date_lettrage 
	ORDER BY date_lettrage );
commit ;

CREATE TABLE listdatepiece_<cloture> (date_piece ) AS 
(SELECT distinct(date_piece )
	FROM fec_<cloture> 
	WHERE date_piece IS NOT NULL 
	GROUP BY date_piece);
commit ;

CREATE TABLE listdatevalidation_<cloture> (valid_date ) AS 
( SELECT distinct(valid_date) 
	FROM fec_<cloture> 
	WHERE valid_date IS NOT NULL 
	GROUP BY valid_date);
commit ;

CREATE TABLE listjournal_<cloture> (code_jrnal , lib_jrnal ) AS 
(SELECT code_jrnal, lib_jrnal 
	FROM fec_<cloture> 
	GROUP BY code_jrnal, lib_jrnal);
commit ;
	
CREATE TABLE listcomptegenaux_<cloture> ( num_cpte_gen_aux  ,  lib_cpte_gen_aux  ) AS 
( SELECT 	"Numéro Compte Gén-Aux","Libellé Compte Gén-Aux" 
	FROM vue_journal_<cloture> 
	GROUP BY "Numéro Compte Gén-Aux", "Libellé Compte Gén-Aux" 	);
commit ;

CREATE TABLE listdevise_<cloture> (devise ) AS 
(SELECT idevise 
	FROM fec_<cloture> WHERE idevise IS NOT NULL AND idevise <> '' 
	GROUP BY idevise);
commit ;

CREATE TABLE listtxtva_<cloture> (taux_tva ) AS
(SELECT taux_tva FROM ecriture_<cloture> WHERE taux_tva IS NOT NULL GROUP BY taux_tva ORDER BY taux_tva ) ;
commit ;

alter table listtxtva_<cloture>  add CONSTRAINT pk_listtxtva_<cloture> PRIMARY KEY (taux_tva) ;


