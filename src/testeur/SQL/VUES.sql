DROP VIEW IF EXISTS vue_balance_<cloture> ;
DROP VIEW IF EXISTS vue_ecriture_<cloture>;
DROP VIEW IF EXISTS vue_ecriture_simple_<cloture>;
DROP VIEW IF EXISTS vue_erreur_<cloture>;



-- Création des vues
CREATE OR REPLACE VIEW vue_balance_<cloture> AS
SELECT min(balance_<cloture>.id_balance) AS "ID",
ltrim(balance_<cloture>.ecr_cte_lig_gen_nid, '0'::text) AS "Numéro Compte",
balance_<cloture>.ecr_cte_lig_gen_lib AS "Libellé Compte",
NULL::unknown AS "Numéro Compte auxiliaire",
NULL::unknown AS "Libellé Compte auxiliaire",
NULL::unknown AS "Numéro Compte Gén-Aux",
NULL::unknown AS "Libellé Compte Gén-Aux",
sum(balance_<cloture>.sld_an_deb) AS "Débit à Nouveau",
sum(balance_<cloture>.sld_an_cre) AS "Crédit à Nouveau",
sum(balance_<cloture>.mass_av_clo_deb) AS "Débit (av. clôture)",
sum(balance_<cloture>.mass_av_clo_cre) AS "Crédit (av. clôture)",
sum(balance_<cloture>.mass_ap_clo_deb) AS "Débit (ap. clôture)",
sum(balance_<cloture>.mass_ap_clo_cre) AS "Crédit (ap. clôture)",
GREATEST(sum(balance_<cloture>.mass_av_clo_deb)-sum(balance_<cloture>.mass_av_clo_cre), 0.0) AS "Solde Débit (av. clôture)",
GREATEST(sum(balance_<cloture>.mass_av_clo_cre)-sum(balance_<cloture>.mass_av_clo_deb), 0.0) AS "Solde Crédit (av. clôture)",
GREATEST(sum(balance_<cloture>.mass_ap_clo_deb)-sum(balance_<cloture>.mass_ap_clo_cre), 0.0) AS "Solde Débit (ap. clôture)",
GREATEST(sum(balance_<cloture>.mass_ap_clo_cre)-sum(balance_<cloture>.mass_ap_clo_deb), 0.0) AS "Solde Crédit (ap. clôture)",
sum(balance_<cloture>.nbr_lign) AS "Nombre lignes",
CASE WHEN sum(nbr_lign) != 0.0 THEN (sum(mass_av_clo_deb)+sum(mass_av_clo_cre)) / sum(nbr_lign) ELSE 0.0 END AS "Montant moyen", 
max(balance_<cloture>.max_lign) AS "Maximum"
 FROM balance_<cloture>
GROUP BY ltrim(balance_<cloture>.ecr_cte_lig_gen_nid, '0'::text), balance_<cloture>.ecr_cte_lig_gen_lib;
-- modif 26/06/2014 : concaténation cpt gén(sans enlever les 0) - cpt aux
CREATE OR REPLACE VIEW vue_balance_aux_<cloture> AS
SELECT balance_<cloture>.id_balance AS "ID",
 ltrim(balance_<cloture>.ecr_cte_lig_gen_nid, '0'::text) AS "Numéro Compte", 
 balance_<cloture>.ecr_cte_lig_gen_lib AS "Libellé Compte", 
 balance_<cloture>.num_cpt_aux AS "Numéro Compte auxiliaire", 
 balance_<cloture>.lib_cpt_aux AS "Libellé Compte auxiliaire", 
 ((balance_<cloture>.ecr_cte_lig_gen_nid)||'-'||(balance_<cloture>.num_cpt_aux)) AS "Numéro Compte Gén-Aux",
 ((balance_<cloture>.ecr_cte_lig_gen_lib)||'-'||(balance_<cloture>.lib_cpt_aux)) AS "Libellé Compte Gén-Aux",
  balance_<cloture>.sld_an_deb AS "Débit à Nouveau", 
 balance_<cloture>.sld_an_cre AS "Crédit à Nouveau", 
 balance_<cloture>.mass_av_clo_deb AS "Débit (av. clôture)", 
 balance_<cloture>.mass_av_clo_cre AS "Crédit (av. clôture)", 
 balance_<cloture>.mass_ap_clo_deb AS "Débit (ap. clôture)", 
 balance_<cloture>.mass_ap_clo_cre AS "Crédit (ap. clôture)", 
 balance_<cloture>.sld_av_clo_mtn_deb AS "Solde Débit (av. clôture)", 
 balance_<cloture>.sld_av_clo_mtn_cre AS "Solde Crédit (av. clôture)", 
 balance_<cloture>.sld_ap_clo_mtn_deb AS "Solde Débit (ap. clôture)", 
 balance_<cloture>.sld_ap_clo_mtn_cre AS "Solde Crédit (ap. clôture)", 
 balance_<cloture>.nbr_lign AS "Nombre lignes", 
 balance_<cloture>.avr_lign_ecr AS "Montant moyen", 
 balance_<cloture>.max_lign AS "Maximum"
  FROM balance_<cloture>; 

CREATE OR REPLACE VIEW vue_ecriture_simple_<cloture> AS
SELECT num_ecr AS "Numéro Ecriture",
code_jrnal AS "Code Journal",
lib_jrnal AS "Journal",
date_cpt AS "Date comptable",
lib_ecriture AS "Tous les Libellés",
sum_debit AS "Débit",
sum_credit AS "Crédit",
date_piece AS "Date Pièce",
num_piece AS "Numéro Pièce",
       CASE
           WHEN taux_tva > 0::numeric THEN 'Créditeur'::text
           WHEN taux_tva < 0::numeric THEN 'Débiteur'::text
           ELSE 'Nul'::text
       END AS "Sens TVA",
abs(taux_tva) AS "Taux TVA",
nb_ligne AS "Nombre de lignes",
       CASE
           WHEN ecr_type = 1 OR ecr_type = 11 THEN 'Clôture'::text
           WHEN ecr_type = 2 OR ecr_type = 12 THEN 'A. Nouveau'::text
           ELSE ''::text
       END AS "Type écriture",
       CASE
           WHEN ecr_type = 11 OR ecr_type = 12 THEN 'Générée'::text
           ELSE ''::text
       END AS "Générée lecode"
  FROM ecriture_<cloture> 
  WHERE ((ecr_type != 11) AND (ecr_type != 12));

CREATE OR REPLACE VIEW vue_ecriture_<cloture> AS
SELECT
       CASE
           WHEN NOT e.idem_codejrnal THEN 'X'::text
           ELSE ''::text
       END AS "Différents codes journaux",
       CASE
           WHEN NOT e.idem_debcre THEN 'X'::text
           ELSE ''::text
       END AS "Ecriture non équilibrée",
       CASE
           WHEN NOT e.idem_datecpt THEN 'X'::text
           ELSE ''::text
       END AS "Différentes dates comptables",
       CASE
           WHEN NOT e.idem_numpiece THEN 'X'::text
           ELSE ''::text
       END AS "Différents numéros de pièce",
       CASE
           WHEN NOT e.idem_datepiece THEN 'X'::text
           ELSE ''::text
       END AS "Différentes dates pièce",
       CASE
           WHEN NOT e.idem_codelet THEN 'X'::text
           ELSE ''::text
       END AS "Différents lettrages",
e.num_ecr AS "Numéro Ecriture",
l.code_jrnal AS "Code Journal",
l.lib_jrnal AS "Journal",
l.date_cpt AS "Date comptable",
l.lib_ecriture AS "Libellé",
e.lib_ecriture AS "Tous les Libellés",
ltrim(l.num_cpte_gen,
'0'::text) AS "Numéro Compte",
l.lib_cpte_gen AS "Libellé Compte",
l.mtn_debit AS "Débit",
l.mtn_credit AS "Crédit",
l.date_piece AS "Date Pièce",
l.num_piece AS "Numéro Pièce",
l.code_lettrage AS "Lettrage",
l.id_ligne AS "ID",
       CASE
           WHEN e.taux_tva > 0::numeric THEN 'Créditeur'::text
           WHEN e.taux_tva < 0::numeric THEN 'Débiteur'::text
           ELSE 'Nul'::text
       END AS "Sens TVA",
abs(e.taux_tva) AS "Taux TVA",
e.nb_ligne AS "Nombre de lignes",
       CASE
           WHEN e.ecr_type = 1 OR e.ecr_type = 11 THEN 'Clôture'::text
           WHEN e.ecr_type = 2 OR e.ecr_type = 12 THEN 'A. Nouveau'::text
           ELSE ''::text
       END AS "Type écriture",
       CASE
           WHEN e.ecr_type = 11 OR e.ecr_type = 12 THEN 'Générée'::text
           ELSE ''::text
       END AS "Générée lecode",
l.num_cpt_aux AS "Numéro Compte auxiliaire",
l.lib_cpt_aux AS "Libellé Compte auxiliaire"
  FROM (select * from ecriture_<cloture> WHERE ((ecr_type != 11) AND (ecr_type != 12))  ) e
  JOIN fec_<cloture> l ON e.num_ecr = l.num_ecr; 
  
CREATE VIEW vue_erreur_<cloture> AS
 SELECT "Différents codes journaux",
"Ecriture non équilibrée",
"Différentes dates comptables",
"Différents numéros de pièce",
"Différentes dates pièce",
"Différents lettrages",
"Numéro Ecriture",
"Code Journal",
"Journal",
"Date comptable",
"Libellé",
"Tous les Libellés",
"Numéro Compte",
"Libellé Compte",
"Débit",
"Crédit",
"Date Pièce",
"Numéro Pièce",
"Lettrage",
"ID",
"Sens TVA",
"Taux TVA",
"Nombre de lignes",
"Type écriture",
"Générée lecode",
"Numéro Compte auxiliaire",
"Libellé Compte auxiliaire"
   FROM vue_ecriture_<cloture>
  WHERE "Différents codes journaux" = 'X'::text
OR "Ecriture non équilibrée" = 'X'::text
OR "Différentes dates comptables" = 'X'::text
OR "Différents numéros de pièce" = 'X'::text
OR "Différentes dates pièce" = 'X'::text
OR "Différents lettrages" = 'X'::text ;



