-- attention syntaxe :  
-- fichier lu à 3 endroits dans le code source, syntaxe strict obligatoire


 

DROP VIEW IF EXISTS vue_journal_<cloture>;

-- modif 27/06/2014 : concaténation cpt gén(sans enlever les 0) - cpt aux
CREATE OR REPLACE VIEW vue_journal_<cloture> AS
SELECT t.id_ligne AS "ID",
t.code_jrnal AS "Code Journal",
t.lib_jrnal AS "Journal",
t.num_ecr AS "Numéro Ecriture",
t.date_cpt AS "Date comptable",
ltrim(t.num_cpte_gen,'0'::text) AS "Numéro Compte",
t.lib_cpte_gen AS "Libellé Compte",
t.num_cpte_gen||COALESCE('-'||t.num_cpt_aux,'') AS "Numéro Compte Gén-Aux",
t.lib_cpte_gen||COALESCE('-'||t.lib_cpt_aux,'') AS "Libellé Compte Gén-Aux",
t.mtn_debit AS "Débit",
t.mtn_credit AS "Crédit",
t.lib_ecriture AS "Libellé",
t.date_piece AS "Date Pièce",
t.num_piece AS "Numéro Pièce",
t.code_lettrage AS "Lettrage",
t.num_cpt_aux AS "Numéro Compte auxiliaire",
t.lib_cpt_aux AS "Libellé Compte auxiliaire",
CASE
            WHEN t.ecr_type = 1 OR t.ecr_type = 11 THEN 'Clôture'::text
            WHEN t.ecr_type = 2 OR t.ecr_type = 12 THEN 'A. Nouveau'::text
            ELSE ''::text
END AS "Type écriture",
CASE 
WHEN t.ecr_type = 11 OR t.ecr_type = 12 THEN 'Générée'::text 
ELSE ''::text 
END AS "Générée lecode",
t.date_lettrage AS "Date Lettrage",
t.valid_date AS "Date Validation",
t.mtn_devise AS "Montant Devise",
t.idevise AS "Devise",
CASE 
			WHEN t.alto2_taux_tva > 0::numeric THEN 'Créditeur' 
			WHEN t.alto2_taux_tva < 0::numeric THEN 'Débiteur' 
			ELSE 'Nul' 
END AS "Sens TVA",
-- 31/07/2015 : ajout de la colonne TVA type
t.tva_type            AS "TVA type", 
abs(t.alto2_taux_tva) AS "Taux TVA" 
<vue_champs_compl>
FROM fec_<cloture> t 
WHERE ((ecr_type != 11) AND (ecr_type != 12));
