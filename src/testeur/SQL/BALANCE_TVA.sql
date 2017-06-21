DROP TABLE IF EXISTS  balance_tva_<cloture> CASCADE;

COMMIT;

--Creation Table balance TVA
CREATE TABLE balance_tva_<cloture> (
  ecr_cte_lig_gen_nid text NOT NULL,
  ecr_cte_lig_gen_lib text NOT NULL,
  num_cpt_aux text,
  lib_cpt_aux text,
  mass_av_clo_deb numeric NOT NULL,
  mass_av_clo_cre numeric NOT NULL,
  sup_m200 numeric,
  _m200 numeric,
  _m200_m196 numeric,
  _m196 numeric,
  _m196_m100 numeric,
  _m100 numeric,
  _m100_m70 numeric,
  _m70 numeric,
  _m70_m55 numeric,
  _m55 numeric,
  _m55_m21 numeric,
  _m21 numeric,
  _m21_00 numeric,
  _00 numeric,
  _00_21 numeric,
  _21 numeric,
  _21_55 numeric,
  _55 numeric,
  _55_70 numeric,
  _70 numeric,
  _70_100 numeric,
  _100 numeric,
  _100_196 numeric,
  _196 numeric,
  _196_200 numeric,
  _200 numeric,
  sup_200 numeric,
  _inv21 numeric,
  _inv55 numeric,
  _inv70 numeric,
  _inv100 numeric,
  _inv196 numeric,
  _inv200 numeric
);

COMMIT;

-- Insertion des donnees dans la table balance TVA
INSERT INTO balance_tva_<cloture> 
SELECT     b."Numéro Compte",
CASE WHEN (b."Libellé Compte") IS NULL THEN '' ELSE b."Libellé Compte" END, 
           b."Numéro Compte auxiliaire", 
	       b."Libellé Compte auxiliaire", 
	       b."Débit (av. clôture)",
	       b."Crédit (av. clôture)",
		sup_m200
		,_m200
		,_m200_m196
		,_m196
		,_m196_m100
		,_m100
		,_m100_m70
		,_m70
		,_m70_m55
		,_m55
		,_m55_m21
		,_m21
		,_m21_00
		,_00
		,_00_21
		, _21
		,_21_55
		,_55
		,_55_70 
		,_70
		,_70_100
		,_100
		,_100_196
		,_196
		,_196_200
		,_200
		,sup_200
FROM vue_balance_aux_<cloture> b 
LEFT OUTER JOIN (SELECT ltrim(num_cpte_gen, '0') AS num_cpte_gen, lib_cpte_gen, (sum(mtn_debit)-sum(mtn_credit)) AS sup_m200, l.num_cpt_aux FROM fec_<cloture> l 
	INNER JOIN (SELECT num_ecr, taux_tva FROM ecriture_<cloture> e) AS t ON l.num_ecr = t.num_ecr 
	WHERE t.taux_tva < -20.05 AND ((ecr_type != 1) AND (ecr_type != 11)) GROUP BY num_cpte_gen, lib_cpte_gen,l.num_cpt_aux)
	AS sup_m200	ON sup_m200.num_cpte_gen = b."Numéro Compte" AND sup_m200.lib_cpte_gen = b."Libellé Compte" and COALESCE(b."Numéro Compte auxiliaire",'') = COALESCE(sup_m200.num_cpt_aux,'')
	LEFT OUTER JOIN (SELECT ltrim(num_cpte_gen, '0') AS num_cpte_gen, lib_cpte_gen, (sum(mtn_debit)-sum(mtn_credit)) AS _m200, l.num_cpt_aux FROM fec_<cloture> l
	INNER JOIN (SELECT num_ecr, taux_tva FROM ecriture_<cloture> e) AS t ON l.num_ecr = t.num_ecr 
	WHERE t.taux_tva >= -20.05 AND t.taux_tva <= -19.95 AND ((ecr_type != 1) AND (ecr_type != 11)) GROUP BY num_cpte_gen, lib_cpte_gen,l.num_cpt_aux) 
	AS _m200 ON _m200.num_cpte_gen = b."Numéro Compte" AND _m200.lib_cpte_gen = b."Libellé Compte" and COALESCE(b."Numéro Compte auxiliaire",'') = COALESCE(_m200.num_cpt_aux,'')
	LEFT OUTER JOIN (SELECT ltrim(num_cpte_gen, '0') AS num_cpte_gen, lib_cpte_gen, (sum(mtn_debit)-sum(mtn_credit)) AS _m200_m196, l.num_cpt_aux FROM fec_<cloture> l 
	INNER JOIN (SELECT num_ecr, taux_tva FROM ecriture_<cloture> e) AS t ON l.num_ecr = t.num_ecr 
	WHERE t.taux_tva > -19.95 AND t.taux_tva < -19.65 AND ((ecr_type != 1) AND (ecr_type != 11)) GROUP BY num_cpte_gen, lib_cpte_gen,l.num_cpt_aux) 
	AS _m200_m196 ON _m200_m196.num_cpte_gen = b."Numéro Compte" AND _m200_m196.lib_cpte_gen = b."Libellé Compte" and COALESCE(b."Numéro Compte auxiliaire",'') = COALESCE(_m200_m196.num_cpt_aux,'')
	LEFT OUTER JOIN (SELECT ltrim(num_cpte_gen, '0') AS num_cpte_gen, lib_cpte_gen, (sum(mtn_debit)-sum(mtn_credit)) AS _m196, l.num_cpt_aux FROM fec_<cloture> l 
	INNER JOIN (SELECT num_ecr, taux_tva FROM ecriture_<cloture> e) AS t ON l.num_ecr = t.num_ecr 
	WHERE t.taux_tva >= -19.65 AND t.taux_tva <= -19.55 AND ((ecr_type != 1) AND (ecr_type != 11)) GROUP BY num_cpte_gen, lib_cpte_gen,l.num_cpt_aux) 
	AS _m196 ON _m196.num_cpte_gen = b."Numéro Compte" AND _m196.lib_cpte_gen = b."Libellé Compte" and COALESCE(b."Numéro Compte auxiliaire",'') = COALESCE(_m196.num_cpt_aux,'')
	LEFT OUTER JOIN (SELECT ltrim(num_cpte_gen, '0') AS num_cpte_gen, lib_cpte_gen, (sum(mtn_debit)-sum(mtn_credit)) AS _m196_m100, l.num_cpt_aux FROM fec_<cloture> l 
	INNER JOIN (SELECT num_ecr, taux_tva FROM ecriture_<cloture> e) AS t ON l.num_ecr = t.num_ecr 
	WHERE t.taux_tva > -19.55 AND t.taux_tva < -10.05 AND ((ecr_type != 1) AND (ecr_type != 11)) GROUP BY num_cpte_gen, lib_cpte_gen,l.num_cpt_aux) 
	AS _m196_m100 ON _m196_m100.num_cpte_gen = b."Numéro Compte" AND _m196_m100.lib_cpte_gen = b."Libellé Compte" and COALESCE(b."Numéro Compte auxiliaire",'') = COALESCE(_m196_m100.num_cpt_aux,'')
	LEFT OUTER JOIN (SELECT ltrim(num_cpte_gen, '0') AS num_cpte_gen, lib_cpte_gen, (sum(mtn_debit)-sum(mtn_credit)) AS _m100, l.num_cpt_aux  FROM fec_<cloture> l 
	INNER JOIN (SELECT num_ecr, taux_tva FROM ecriture_<cloture> e) AS t ON l.num_ecr = t.num_ecr 
	WHERE t.taux_tva >= -10.05 AND t.taux_tva <= -9.95 AND ((ecr_type != 1) AND (ecr_type != 11)) GROUP BY num_cpte_gen, lib_cpte_gen, l.num_cpt_aux ) 
	AS _m100 ON _m100.num_cpte_gen = b."Numéro Compte" AND _m100.lib_cpte_gen = b."Libellé Compte" and COALESCE(b."Numéro Compte auxiliaire",'') = COALESCE(_m100.num_cpt_aux,'')
	LEFT OUTER JOIN (SELECT ltrim(num_cpte_gen, '0') AS num_cpte_gen, lib_cpte_gen, (sum(mtn_debit)-sum(mtn_credit)) AS _m100_m70, l.num_cpt_aux FROM fec_<cloture> l 
	INNER JOIN (SELECT num_ecr, taux_tva FROM ecriture_<cloture> e) AS t ON l.num_ecr = t.num_ecr 
	WHERE t.taux_tva > -9.95 AND t.taux_tva < -7.05 AND ((ecr_type != 1) AND (ecr_type != 11)) GROUP BY num_cpte_gen, lib_cpte_gen, l.num_cpt_aux) 
	AS _m100_m70 ON _m100_m70.num_cpte_gen = b."Numéro Compte" AND _m100_m70.lib_cpte_gen = b."Libellé Compte" and COALESCE(b."Numéro Compte auxiliaire",'') = COALESCE(_m100_m70.num_cpt_aux,'')
	LEFT OUTER JOIN (SELECT ltrim(num_cpte_gen, '0') AS num_cpte_gen, lib_cpte_gen, (sum(mtn_debit)-sum(mtn_credit)) AS _m70, l.num_cpt_aux FROM fec_<cloture> l 
	INNER JOIN (SELECT num_ecr, taux_tva FROM ecriture_<cloture> e) AS t ON l.num_ecr = t.num_ecr 
	WHERE t.taux_tva >= -7.05 AND t.taux_tva <= -6.95 AND ((ecr_type != 1) AND (ecr_type != 11)) GROUP BY num_cpte_gen, lib_cpte_gen, l.num_cpt_aux) 
	AS _m70 ON _m70.num_cpte_gen = b."Numéro Compte" AND _m70.lib_cpte_gen = b."Libellé Compte" and COALESCE(b."Numéro Compte auxiliaire",'') = COALESCE(_m70.num_cpt_aux,'')
	LEFT OUTER JOIN (SELECT ltrim(num_cpte_gen, '0') AS num_cpte_gen, lib_cpte_gen, (sum(mtn_debit)-sum(mtn_credit)) AS _m70_m55, l.num_cpt_aux FROM fec_<cloture> l 
	INNER JOIN (SELECT num_ecr, taux_tva FROM ecriture_<cloture> e) AS t ON l.num_ecr = t.num_ecr 
	WHERE t.taux_tva > -6.95 AND t.taux_tva < -5.55 AND ((ecr_type != 1) AND (ecr_type != 11)) GROUP BY num_cpte_gen, lib_cpte_gen, l.num_cpt_aux) 
	AS _m70_m55 ON _m70_m55.num_cpte_gen = b."Numéro Compte" AND _m70_m55.lib_cpte_gen = b."Libellé Compte" and COALESCE(b."Numéro Compte auxiliaire",'') = COALESCE(_m70_m55.num_cpt_aux,'')
	LEFT OUTER JOIN (SELECT ltrim(num_cpte_gen, '0') AS num_cpte_gen, lib_cpte_gen, (sum(mtn_debit)-sum(mtn_credit)) AS _m55, l.num_cpt_aux FROM fec_<cloture> l 
	INNER JOIN (SELECT num_ecr, taux_tva FROM ecriture_<cloture> e) AS t ON l.num_ecr = t.num_ecr 
	WHERE t.taux_tva >= -5.55 AND t.taux_tva <= -5.45 AND ((ecr_type != 1) AND (ecr_type != 11)) GROUP BY num_cpte_gen, lib_cpte_gen, l.num_cpt_aux) 
	AS _m55 ON _m55.num_cpte_gen = b."Numéro Compte" AND _m55.lib_cpte_gen = b."Libellé Compte" and COALESCE(b."Numéro Compte auxiliaire",'') = COALESCE(_m55.num_cpt_aux,'')
	LEFT OUTER JOIN (SELECT ltrim(num_cpte_gen, '0') AS num_cpte_gen, lib_cpte_gen, (sum(mtn_debit)-sum(mtn_credit)) AS _m55_m21, l.num_cpt_aux FROM fec_<cloture> l 
	INNER JOIN (SELECT num_ecr, taux_tva FROM ecriture_<cloture> e) AS t ON l.num_ecr = t.num_ecr 
	WHERE t.taux_tva > -5.45 AND t.taux_tva < -2.15 AND ((ecr_type != 1) AND (ecr_type != 11)) GROUP BY num_cpte_gen, lib_cpte_gen, l.num_cpt_aux) 
	AS _m55_m21 ON _m55_m21.num_cpte_gen = b."Numéro Compte" AND _m55_m21.lib_cpte_gen = b."Libellé Compte" and COALESCE(b."Numéro Compte auxiliaire",'') = COALESCE(_m55_m21.num_cpt_aux,'')
	LEFT OUTER JOIN (SELECT ltrim(num_cpte_gen, '0') AS num_cpte_gen, lib_cpte_gen, (sum(mtn_debit)-sum(mtn_credit)) AS _m21, l.num_cpt_aux FROM fec_<cloture> l 
	INNER JOIN (SELECT num_ecr, taux_tva FROM ecriture_<cloture> e) AS t ON l.num_ecr = t.num_ecr 
	WHERE t.taux_tva >= -2.15 AND t.taux_tva <= -2.05 AND ((ecr_type != 1) AND (ecr_type != 11)) GROUP BY num_cpte_gen, lib_cpte_gen, l.num_cpt_aux) 
	AS _m21 ON _m21.num_cpte_gen = b."Numéro Compte" AND _m21.lib_cpte_gen = b."Libellé Compte" and COALESCE(b."Numéro Compte auxiliaire",'') = COALESCE(_m21.num_cpt_aux,'')
	LEFT OUTER JOIN (SELECT ltrim(num_cpte_gen, '0') AS num_cpte_gen, lib_cpte_gen, (sum(mtn_debit)-sum(mtn_credit)) AS _m21_00, l.num_cpt_aux FROM fec_<cloture> l 
	INNER JOIN (SELECT num_ecr, taux_tva FROM ecriture_<cloture> e) AS t ON l.num_ecr = t.num_ecr 
	WHERE t.taux_tva > -2.05 AND t.taux_tva < -0.05 AND ((ecr_type != 1) AND (ecr_type != 11)) GROUP BY num_cpte_gen, lib_cpte_gen, l.num_cpt_aux) 
	AS _m21_00 ON _m21_00.num_cpte_gen = b."Numéro Compte" AND _m21_00.lib_cpte_gen = b."Libellé Compte" and COALESCE(b."Numéro Compte auxiliaire",'') = COALESCE(_m21_00.num_cpt_aux,'')
LEFT OUTER JOIN (SELECT ltrim(num_cpte_gen, '0') AS num_cpte_gen, lib_cpte_gen, (sum(mtn_debit)-sum(mtn_credit)) AS _00, l.num_cpt_aux FROM fec_<cloture> l 
	INNER JOIN (SELECT num_ecr, taux_tva FROM ecriture_<cloture> e) AS t ON l.num_ecr = t.num_ecr 
	WHERE t.taux_tva >= -0.05 AND t.taux_tva <= 0.05 AND ((ecr_type != 1) AND (ecr_type != 11)) GROUP BY num_cpte_gen, lib_cpte_gen, l.num_cpt_aux) 
	AS _00 ON _00.num_cpte_gen = b."Numéro Compte" AND _00.lib_cpte_gen = b."Libellé Compte" and COALESCE(b."Numéro Compte auxiliaire",'') = COALESCE(_00.num_cpt_aux,'')
	LEFT OUTER JOIN (SELECT ltrim(num_cpte_gen, '0') AS num_cpte_gen, lib_cpte_gen, (sum(mtn_debit)-sum(mtn_credit)) AS _00_21, l.num_cpt_aux FROM fec_<cloture> l 
	INNER JOIN (SELECT num_ecr, taux_tva FROM ecriture_<cloture> e) AS t ON l.num_ecr = t.num_ecr 
	WHERE t.taux_tva > 0.05 AND t.taux_tva < 2.05 AND ((ecr_type != 1) AND (ecr_type != 11)) GROUP BY num_cpte_gen, lib_cpte_gen, l.num_cpt_aux) 
	AS _00_21 ON _00_21.num_cpte_gen = b."Numéro Compte" AND _00_21.lib_cpte_gen = b."Libellé Compte" and COALESCE(b."Numéro Compte auxiliaire",'') = COALESCE(_00_21.num_cpt_aux,'')
	LEFT OUTER JOIN (SELECT ltrim(num_cpte_gen, '0') AS num_cpte_gen, lib_cpte_gen, (sum(mtn_debit)-sum(mtn_credit)) AS _21, l.num_cpt_aux FROM fec_<cloture> l 
	INNER JOIN (SELECT num_ecr, taux_tva FROM ecriture_<cloture> e) AS t ON l.num_ecr = t.num_ecr 
	WHERE t.taux_tva <= 2.15 AND t.taux_tva >= 2.05 AND ((ecr_type != 1) AND (ecr_type != 11)) GROUP BY num_cpte_gen, lib_cpte_gen, l.num_cpt_aux) 
	AS _21 ON _21.num_cpte_gen = b."Numéro Compte" AND _21.lib_cpte_gen = b."Libellé Compte" and COALESCE(b."Numéro Compte auxiliaire",'') = COALESCE(_21.num_cpt_aux,'')
	LEFT OUTER JOIN (SELECT ltrim(num_cpte_gen, '0') AS num_cpte_gen, lib_cpte_gen, (sum(mtn_debit)-sum(mtn_credit)) AS _21_55, l.num_cpt_aux FROM fec_<cloture> l 
	INNER JOIN (SELECT num_ecr, taux_tva FROM ecriture_<cloture> e) AS t ON l.num_ecr = t.num_ecr 
	WHERE t.taux_tva > 2.15 AND t.taux_tva < 5.45 AND ((ecr_type != 1) AND (ecr_type != 11)) GROUP BY num_cpte_gen, lib_cpte_gen, l.num_cpt_aux) 
	AS _21_55 ON _21_55.num_cpte_gen = b."Numéro Compte" AND _21_55.lib_cpte_gen = b."Libellé Compte" and COALESCE(b."Numéro Compte auxiliaire",'') = COALESCE(_21_55.num_cpt_aux,'')
	LEFT OUTER JOIN (SELECT ltrim(num_cpte_gen, '0') AS num_cpte_gen, lib_cpte_gen, (sum(mtn_debit)-sum(mtn_credit)) AS _55, l.num_cpt_aux FROM fec_<cloture> l 
	INNER JOIN (SELECT num_ecr, taux_tva FROM ecriture_<cloture> e) AS t ON l.num_ecr = t.num_ecr 
	WHERE t.taux_tva <= 5.55 AND t.taux_tva >= 5.45 AND ((ecr_type != 1) AND (ecr_type != 11)) GROUP BY num_cpte_gen, lib_cpte_gen, l.num_cpt_aux) 
	AS _55 ON _55.num_cpte_gen = b."Numéro Compte" AND _55.lib_cpte_gen = b."Libellé Compte" and COALESCE(b."Numéro Compte auxiliaire",'') = COALESCE(_55.num_cpt_aux,'')
	LEFT OUTER JOIN (SELECT ltrim(num_cpte_gen, '0') AS num_cpte_gen, lib_cpte_gen, (sum(mtn_debit)-sum(mtn_credit)) AS _55_70, l.num_cpt_aux FROM fec_<cloture> l 
	INNER JOIN (SELECT num_ecr, taux_tva FROM ecriture_<cloture> e) AS t ON l.num_ecr = t.num_ecr 
	WHERE t.taux_tva > 5.55 AND t.taux_tva < 6.95 AND ((ecr_type != 1) AND (ecr_type != 11)) GROUP BY num_cpte_gen, lib_cpte_gen, l.num_cpt_aux) 
	AS _55_70 ON _55_70.num_cpte_gen = b."Numéro Compte" AND _55_70.lib_cpte_gen = b."Libellé Compte" and COALESCE(b."Numéro Compte auxiliaire",'') = COALESCE(_55_70.num_cpt_aux,'')
	LEFT OUTER JOIN (SELECT ltrim(num_cpte_gen, '0') AS num_cpte_gen, lib_cpte_gen, (sum(mtn_debit)-sum(mtn_credit)) AS _70, l.num_cpt_aux FROM fec_<cloture> l 
	INNER JOIN (SELECT num_ecr, taux_tva FROM ecriture_<cloture> e) AS t ON l.num_ecr = t.num_ecr 
	WHERE t.taux_tva <= 7.05 AND t.taux_tva >= 6.95 AND ((ecr_type != 1) AND (ecr_type != 11)) GROUP BY num_cpte_gen, lib_cpte_gen, l.num_cpt_aux) 
	AS _70 ON _70.num_cpte_gen = b."Numéro Compte" AND _70.lib_cpte_gen = b."Libellé Compte" and COALESCE(b."Numéro Compte auxiliaire",'') = COALESCE(_70.num_cpt_aux,'')
	LEFT OUTER JOIN (SELECT ltrim(num_cpte_gen, '0') AS num_cpte_gen, lib_cpte_gen, (sum(mtn_debit)-sum(mtn_credit)) AS _70_100, l.num_cpt_aux FROM fec_<cloture> l 
	INNER JOIN (SELECT num_ecr, taux_tva FROM ecriture_<cloture> e) AS t ON l.num_ecr = t.num_ecr 
	WHERE t.taux_tva > 7.05 AND t.taux_tva < 9.95 AND ((ecr_type != 1) AND (ecr_type != 11)) GROUP BY num_cpte_gen, lib_cpte_gen, l.num_cpt_aux) 
	AS _70_100 ON _70_100.num_cpte_gen = b."Numéro Compte" AND _70_100.lib_cpte_gen = b."Libellé Compte" and COALESCE(b."Numéro Compte auxiliaire",'') = COALESCE(_70_100.num_cpt_aux,'')
	LEFT OUTER JOIN (SELECT ltrim(num_cpte_gen, '0') AS num_cpte_gen, lib_cpte_gen, (sum(mtn_debit)-sum(mtn_credit)) AS _100, l.num_cpt_aux FROM fec_<cloture> l 
	INNER JOIN (SELECT num_ecr, taux_tva FROM ecriture_<cloture> e) AS t ON l.num_ecr = t.num_ecr 
	WHERE t.taux_tva <= 10.05 AND t.taux_tva >= 9.95 AND ((ecr_type != 1) AND (ecr_type != 11)) GROUP BY num_cpte_gen, lib_cpte_gen, l.num_cpt_aux) 
	AS _100 ON _100.num_cpte_gen = b."Numéro Compte" AND _100.lib_cpte_gen = b."Libellé Compte" and COALESCE(b."Numéro Compte auxiliaire",'') = COALESCE(_100.num_cpt_aux,'')
	LEFT OUTER JOIN (SELECT ltrim(num_cpte_gen, '0') AS num_cpte_gen, lib_cpte_gen, (sum(mtn_debit)-sum(mtn_credit)) AS _100_196, l.num_cpt_aux FROM fec_<cloture> l 
	INNER JOIN (SELECT num_ecr, taux_tva FROM ecriture_<cloture> e) AS t ON l.num_ecr = t.num_ecr 
	WHERE t.taux_tva > 10.05 AND t.taux_tva < 19.55 AND ((ecr_type != 1) AND (ecr_type != 11)) GROUP BY num_cpte_gen, lib_cpte_gen, l.num_cpt_aux) 
	AS _100_196 ON _100_196.num_cpte_gen = b."Numéro Compte" AND _100_196.lib_cpte_gen = b."Libellé Compte" and COALESCE(b."Numéro Compte auxiliaire",'') = COALESCE(_100_196.num_cpt_aux,'')
	LEFT OUTER JOIN (SELECT ltrim(num_cpte_gen, '0') AS num_cpte_gen, lib_cpte_gen, (sum(mtn_debit)-sum(mtn_credit)) AS _196, l.num_cpt_aux FROM fec_<cloture> l 
	INNER JOIN (SELECT num_ecr, taux_tva FROM ecriture_<cloture> e) AS t ON l.num_ecr = t.num_ecr 
	WHERE t.taux_tva <= 19.65 AND t.taux_tva >= 19.55 AND ((ecr_type != 1) AND (ecr_type != 11)) GROUP BY num_cpte_gen, lib_cpte_gen, l.num_cpt_aux) 
	AS _196 ON _196.num_cpte_gen = b."Numéro Compte" AND _196.lib_cpte_gen = b."Libellé Compte" and COALESCE(b."Numéro Compte auxiliaire",'') = COALESCE(_196.num_cpt_aux,'')
	LEFT OUTER JOIN (SELECT ltrim(num_cpte_gen, '0') AS num_cpte_gen, lib_cpte_gen, (sum(mtn_debit)-sum(mtn_credit)) AS _196_200, l.num_cpt_aux FROM fec_<cloture> l 
	INNER JOIN (SELECT num_ecr, taux_tva FROM ecriture_<cloture> e) AS t ON l.num_ecr = t.num_ecr 
	WHERE t.taux_tva > 19.65 AND t.taux_tva < 19.95 AND ((ecr_type != 1) AND (ecr_type != 11)) GROUP BY num_cpte_gen, lib_cpte_gen, l.num_cpt_aux) 
	AS _196_200 ON _196_200.num_cpte_gen = b."Numéro Compte" AND _196_200.lib_cpte_gen = b."Libellé Compte" and COALESCE(b."Numéro Compte auxiliaire",'') = COALESCE(_196_200.num_cpt_aux,'')
	LEFT OUTER JOIN (SELECT ltrim(num_cpte_gen, '0') AS num_cpte_gen, lib_cpte_gen, (sum(mtn_debit)-sum(mtn_credit)) AS _200, l.num_cpt_aux FROM fec_<cloture> l 
	INNER JOIN (SELECT num_ecr, taux_tva FROM ecriture_<cloture> e) AS t ON l.num_ecr = t.num_ecr 
	WHERE t.taux_tva <= 20.05 AND t.taux_tva >= 19.95 AND ((ecr_type != 1) AND (ecr_type != 11)) GROUP BY num_cpte_gen, lib_cpte_gen, l.num_cpt_aux) 
	AS _200 ON _200.num_cpte_gen = b."Numéro Compte" AND _200.lib_cpte_gen = b."Libellé Compte" and COALESCE(b."Numéro Compte auxiliaire",'') = COALESCE(_200.num_cpt_aux,'')
	LEFT OUTER JOIN (SELECT ltrim(num_cpte_gen, '0') AS num_cpte_gen, lib_cpte_gen, (sum(mtn_debit)-sum(mtn_credit)) AS sup_200, l.num_cpt_aux FROM fec_<cloture> l 
	INNER JOIN (SELECT num_ecr, taux_tva FROM ecriture_<cloture> e) AS t ON l.num_ecr = t.num_ecr 
	WHERE t.taux_tva > 20.05 AND ((ecr_type != 1) AND (ecr_type != 11)) GROUP BY num_cpte_gen, lib_cpte_gen, l.num_cpt_aux) 
	AS sup_200 ON sup_200.num_cpte_gen = b."Numéro Compte" AND sup_200.lib_cpte_gen = b."Libellé Compte" and COALESCE(b."Numéro Compte auxiliaire",'') = COALESCE(sup_200.num_cpt_aux,'')
	order by b."Numéro Compte", b."Numéro Compte auxiliaire"
;

COMMIT;

UPDATE balance_tva_<cloture> SET sup_m200=0.0 WHERE sup_m200 IS NULL;
UPDATE balance_tva_<cloture> SET _m200=0.0 WHERE _m200 IS NULL;
UPDATE balance_tva_<cloture> SET _m200_m196=0.0 WHERE _m200_m196 IS NULL;
UPDATE balance_tva_<cloture> SET _m196=0.0 WHERE _m196 IS NULL;
UPDATE balance_tva_<cloture> SET _m196_m100=0.0 WHERE _m196_m100 IS NULL;
UPDATE balance_tva_<cloture> SET _m100=0.0 WHERE _m100 IS NULL;
UPDATE balance_tva_<cloture> SET _m100_m70=0.0 WHERE _m100_m70 IS NULL;
UPDATE balance_tva_<cloture> SET _m70=0.0 WHERE _m70 IS NULL;
UPDATE balance_tva_<cloture> SET _m70_m55=0.0 WHERE _m70_m55 IS NULL;
UPDATE balance_tva_<cloture> SET _m55=0.0 WHERE _m55 IS NULL;
UPDATE balance_tva_<cloture> SET _m55_m21=0.0 WHERE _m55_m21 IS NULL;
UPDATE balance_tva_<cloture> SET _m21=0.0 WHERE _m21 IS NULL;
UPDATE balance_tva_<cloture> SET _m21_00=0.0 WHERE _m21_00 IS NULL;
UPDATE balance_tva_<cloture> SET _00=0.0 WHERE _00 IS NULL;
UPDATE balance_tva_<cloture> SET _00_21=0.0 WHERE _00_21 IS NULL;
UPDATE balance_tva_<cloture> SET _21=0.0 WHERE _21 IS NULL;
UPDATE balance_tva_<cloture> SET _21_55=0.0 WHERE _21_55 IS NULL;
UPDATE balance_tva_<cloture> SET _55=0.0 WHERE _55 IS NULL;
UPDATE balance_tva_<cloture> SET _55_70=0.0 WHERE _55_70 IS NULL;
UPDATE balance_tva_<cloture> SET _70=0.0 WHERE _70 IS NULL;
UPDATE balance_tva_<cloture> SET _70_100=0.0 WHERE _70_100 IS NULL;
UPDATE balance_tva_<cloture> SET _100=0.0 WHERE _100 IS NULL;
UPDATE balance_tva_<cloture> SET _100_196=0.0 WHERE _100_196 IS NULL;
UPDATE balance_tva_<cloture> SET _196=0.0 WHERE _196 IS NULL;
UPDATE balance_tva_<cloture> SET _196_200=0.0 WHERE _196_200 IS NULL;
UPDATE balance_tva_<cloture> SET _200=0.0 WHERE _200 IS NULL;
UPDATE balance_tva_<cloture> SET sup_200=0.0 WHERE sup_200 IS NULL;

UPDATE balance_tva_<cloture> SET _inv21 = val FROM ( 	SELECT ltrim(num_cpte_gen, '0') AS num_cpte_gen, lib_cpte_gen, sum(mtn_debit)+sum(mtn_credit) AS val 	FROM fec_<cloture>	WHERE num_ecr IN (SELECT num_ecr FROM ecriture_<cloture> WHERE @taux_tva = round(@ 100/(2.1/100), 1)) 	GROUP BY ltrim(num_cpte_gen, '0'), lib_cpte_gen ) AS t WHERE ecr_cte_lig_gen_nid = t.num_cpte_gen AND ecr_cte_lig_gen_lib = t.lib_cpte_gen; 
UPDATE balance_tva_<cloture> SET _inv55 = val FROM ( 	SELECT ltrim(num_cpte_gen, '0') AS num_cpte_gen, lib_cpte_gen, sum(mtn_debit)+sum(mtn_credit) AS val 	FROM fec_<cloture>	WHERE num_ecr IN (SELECT num_ecr FROM ecriture_<cloture> WHERE @taux_tva = round(@ 100/(5.5/100), 1)) 	GROUP BY ltrim(num_cpte_gen, '0'), lib_cpte_gen ) AS t WHERE ecr_cte_lig_gen_nid = t.num_cpte_gen AND ecr_cte_lig_gen_lib = t.lib_cpte_gen; 
UPDATE balance_tva_<cloture> SET _inv70 = val FROM ( 	SELECT ltrim(num_cpte_gen, '0') AS num_cpte_gen, lib_cpte_gen, sum(mtn_debit)+sum(mtn_credit) AS val 	FROM fec_<cloture>	WHERE num_ecr IN (SELECT num_ecr FROM ecriture_<cloture> WHERE @taux_tva = round(@ 100/(7.0/100), 1)) 	GROUP BY ltrim(num_cpte_gen, '0'), lib_cpte_gen ) AS t WHERE ecr_cte_lig_gen_nid = t.num_cpte_gen AND ecr_cte_lig_gen_lib = t.lib_cpte_gen; 
UPDATE balance_tva_<cloture> SET _inv100 = val FROM ( 	SELECT ltrim(num_cpte_gen, '0') AS num_cpte_gen, lib_cpte_gen, sum(mtn_debit)+sum(mtn_credit) AS val 	FROM fec_<cloture>	WHERE num_ecr IN (SELECT num_ecr FROM ecriture_<cloture> WHERE @taux_tva = round(@ 100/(10.0/100), 1)) 	GROUP BY ltrim(num_cpte_gen, '0'), lib_cpte_gen ) AS t WHERE ecr_cte_lig_gen_nid = t.num_cpte_gen AND ecr_cte_lig_gen_lib = t.lib_cpte_gen; 
UPDATE balance_tva_<cloture> SET _inv196 = val FROM ( 	SELECT ltrim(num_cpte_gen, '0') AS num_cpte_gen, lib_cpte_gen, sum(mtn_debit)+sum(mtn_credit) AS val 	FROM fec_<cloture>	WHERE num_ecr IN (SELECT num_ecr FROM ecriture_<cloture> WHERE @taux_tva = round(@ 100/(19.6/100), 1)) 	GROUP BY ltrim(num_cpte_gen, '0'), lib_cpte_gen ) AS t WHERE ecr_cte_lig_gen_nid = t.num_cpte_gen AND ecr_cte_lig_gen_lib = t.lib_cpte_gen; 
UPDATE balance_tva_<cloture> SET _inv200 = val FROM ( 	SELECT ltrim(num_cpte_gen, '0') AS num_cpte_gen, lib_cpte_gen, sum(mtn_debit)+sum(mtn_credit) AS val 	FROM fec_<cloture>	WHERE num_ecr IN (SELECT num_ecr FROM ecriture_<cloture> WHERE @taux_tva = round(@ 100/(20.0/100), 1)) 	GROUP BY ltrim(num_cpte_gen, '0'), lib_cpte_gen ) AS t WHERE ecr_cte_lig_gen_nid = t.num_cpte_gen AND ecr_cte_lig_gen_lib = t.lib_cpte_gen; 

UPDATE balance_tva_<cloture> SET _inv21=0.0 WHERE _inv21 IS NULL;
UPDATE balance_tva_<cloture> SET _inv55=0.0 WHERE _inv55 IS NULL;
UPDATE balance_tva_<cloture> SET _inv70=0.0 WHERE _inv70 IS NULL;
UPDATE balance_tva_<cloture> SET _inv100=0.0 WHERE _inv100 IS NULL;
UPDATE balance_tva_<cloture> SET _inv196=0.0 WHERE _inv196 IS NULL;
UPDATE balance_tva_<cloture> SET _inv200=0.0 WHERE _inv200 IS NULL;


COMMIT;