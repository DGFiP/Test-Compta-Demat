

  SELECT d.lib_dir AS "Dossier", a.lib_axe AS "Libellé axe", '<datecloture>'::date AS "Exercice", t.code_jrnal AS "Code Journal", t.lib_jrnal AS "Journal", t.num_ecr AS "Numéro Ecriture", t.date_cpt AS "Date comptable", ltrim(t.num_cpte_gen, '0'::text) AS "Numéro Compte", t.lib_cpte_gen AS "Libellé Compte", t.num_cpt_aux AS "Numéro Compte auxiliaire", t.lib_cpt_aux AS "Libellé Compte auxiliaire",
  t.num_cpte_gen||COALESCE('-'||t.num_cpt_aux,'') AS "Numéro Compte Gén-Aux", t.lib_cpte_gen||COALESCE('-'||t.lib_cpt_aux,'') AS "Libellé Compte Gén-Aux", 
  t.num_piece AS "Numéro Pièce", t.date_piece AS "Date Pièce", t.lib_ecriture AS "Libellé", t.mtn_debit AS "Débit", t.mtn_credit AS "Crédit", t.code_lettrage AS "Lettrage", t.date_lettrage AS "Date Lettrage", t.valid_date AS "Date Validation", t.mtn_devise AS "Montant Devise", t.idevise AS "Devise",
                CASE
                    WHEN t.ecr_type = 1 OR t.ecr_type = 11 THEN 'Clôture'::text
                    WHEN t.ecr_type = 2 OR t.ecr_type = 12 THEN 'A. Nouveau'::text
                    ELSE ''::text
                END AS "Type écriture",
                CASE
                    WHEN t.ecr_type = 11 OR t.ecr_type = 12 THEN 'Générée'::text
                    ELSE ''::text
                END AS "Générée lecode", a.id_panier_dir AS "ID_DIR", a.id_panier_axe AS "ID_AXE", p.id_ligne AS "ID_LIGNE"
           FROM panier_axe a
      JOIN panier_dir d ON d.id_panier_dir = a.id_panier_dir
   JOIN panier_ligne p ON p.id_panier_axe = a.id_panier_axe
   JOIN fec_<cloture> t ON p.id_ligne = t.id_ligne AND p.exercice = '<datecloture>'::date
   