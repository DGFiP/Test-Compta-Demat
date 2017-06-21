DROP VIEW IF EXISTS vue_balance_tva_<cloture>;

COMMIT;

CREATE OR REPLACE VIEW vue_balance_tva_<cloture> AS 
 SELECT ltrim(balance_tva_<cloture>.ecr_cte_lig_gen_nid, '0'::text) AS "Numéro Compte", 
                          balance_tva_<cloture>.ecr_cte_lig_gen_lib AS "Libellé Compte", 
						  balance_tva_<cloture>.num_cpt_aux         AS "Numéro Compte auxiliaire", 
						  balance_tva_<cloture>.lib_cpt_aux         AS "Libellé Compte auxiliaire", 
						  balance_tva_<cloture>.ecr_cte_lig_gen_nid || COALESCE('-'::text || balance_tva_<cloture>.num_cpt_aux, ''::text) AS "Numéro Compte Gén-Aux",
						  balance_tva_<cloture>.ecr_cte_lig_gen_lib || COALESCE('-'::text || balance_tva_<cloture>.lib_cpt_aux, ''::text) AS "Libellé Compte Gén-Aux",
						  balance_tva_<cloture>.mass_av_clo_deb AS "Débit (av. clôture)", 
						  balance_tva_<cloture>.mass_av_clo_cre AS "Crédit (av. clôture)", 
						  balance_tva_<cloture>.sup_m200 AS "TVA débitrice  > 20.0%", 
						  balance_tva_<cloture>._m200 AS "TVA débitrice 20.0%", 
						  balance_tva_<cloture>._m200_m196 AS "TVA débitrice 19.6% - 20.0%", 
						  balance_tva_<cloture>._m196 AS "TVA débitrice 19.6%", 
						  balance_tva_<cloture>._m196_m100 AS "TVA débitrice 10.0% - 19.6%",
						  balance_tva_<cloture>._m100 AS "TVA débitrice 10.0%",
						  balance_tva_<cloture>._m100_m70 AS "TVA débitrice 7.0% - 10.0%",
						  balance_tva_<cloture>._m70 AS "TVA débitrice 7.0%", 
						  balance_tva_<cloture>._m70_m55 AS "TVA débitrice 5.5% - 7.0%", 
						  balance_tva_<cloture>._m55 AS "TVA débitrice 5.5%",
						  balance_tva_<cloture>._m55_m21 AS "TVA débitrice 2.1% - 5.5%", 
						  balance_tva_<cloture>._m21 AS "TVA débitrice 2.1%", 
						  balance_tva_<cloture>._m21_00 AS "TVA débitrice -0.0% - 2.1%", 
						  balance_tva_<cloture>._00 AS "TVA nulle", 
						  balance_tva_<cloture>._00_21 AS "TVA créditrice 0.0% - 2.1%", 
						  balance_tva_<cloture>._21 AS "TVA créditrice 2.1%", 
						  balance_tva_<cloture>._21_55 AS "TVA créditrice 2.1% - 5.5%", 
						  balance_tva_<cloture>._55 AS "TVA créditrice 5.5%", 
						  balance_tva_<cloture>._55_70 AS "TVA créditrice 5.5% - 7.0%", 
						  balance_tva_<cloture>._70 AS "TVA créditrice 7.0%", 
						  balance_tva_<cloture>._70_100 AS "TVA créditrice 7.0% - 10.0%", 
						  balance_tva_<cloture>._100 AS "TVA créditrice 10.0%", 
						  balance_tva_<cloture>._100_196 AS "TVA créditrice 10.0% - 19.6%", 
						  balance_tva_<cloture>._196 AS "TVA créditrice 19.6%", 
						  balance_tva_<cloture>._196_200 AS "TVA créditrice 19.6% - 20.0%", 
						  balance_tva_<cloture>._200 AS "TVA créditrice 20.0%", 
						  balance_tva_<cloture>.sup_200 AS "TVA créditrice  > 20.0%", 
						  balance_tva_<cloture>._00 AS "TVA 0.0%", 
						  balance_tva_<cloture>._m21_00 + balance_tva_<cloture>._00_21 AS "TVA 0.0% - 2.1%",
						  balance_tva_<cloture>._m21 + balance_tva_<cloture>._21 AS "TVA 2.1%", 
						  balance_tva_<cloture>._m55_m21 + balance_tva_<cloture>._21_55 AS "TVA 2.1% - 5.5%", 
						  balance_tva_<cloture>._m55 + balance_tva_<cloture>._55 AS "TVA 5.5%", 
						  balance_tva_<cloture>._m70_m55 + balance_tva_<cloture>._55_70 AS "TVA 5.5% - 7.0%", 
						  balance_tva_<cloture>._m70 + balance_tva_<cloture>._70 AS "TVA 7.0%", 
						  balance_tva_<cloture>._m100_m70 + balance_tva_<cloture>._70_100 AS "TVA 7.0% - 10.0%", 
						  balance_tva_<cloture>._m100 + balance_tva_<cloture>._100 AS "TVA 10.0%", 
						  balance_tva_<cloture>._m196_m100 + balance_tva_<cloture>._100_196 AS "TVA 10.0% - 19.6%", 
						  balance_tva_<cloture>._m196 + balance_tva_<cloture>._196 AS "TVA 19.6%", 
						  balance_tva_<cloture>._m200_m196 + balance_tva_<cloture>._196_200 AS "TVA 19.6% - 20.0%",
						  balance_tva_<cloture>._m200 + balance_tva_<cloture>._200 AS "TVA 20.0%", 
						  balance_tva_<cloture>.sup_m200 + balance_tva_<cloture>.sup_200 AS "TVA > 20.0%",
						  balance_tva_<cloture>._inv21 AS "Inversion 2.1%",
						  balance_tva_<cloture>._inv55 AS "Inversion 5.5%",
						  balance_tva_<cloture>._inv70 AS "Inversion 7.0%",
						  balance_tva_<cloture>._inv100 AS "Inversion 10.0%",
						  balance_tva_<cloture>._inv196 AS "Inversion 19.6%",
						  balance_tva_<cloture>._inv200 AS "Inversion 20.0%"
FROM balance_tva_<cloture>;

COMMIT;

-- La ligne existe déjà : cas des dossiers existants ----
UPDATE PARAMETRE set valeur='true' where id='BalanceTVAInit';
COMMIT;

--- La ligne n'existe pas : cas des nouveaux dossiers ---------------
INSERT INTO parametre VALUES ('BalanceTVAInit', 'true');
COMMIT;

----- La ligne existe déjà ----------
UPDATE PARAMETRE set valeur='2.1#5.5#7.0#10.0#19.6#20.0#' where id='TxTVA';
COMMIT;

----- La ligne n'existe pas ----------
INSERT INTO parametre VALUES ('TxTVA', '2.1#5.5#7.0#10.0#19.6#20.0#');
COMMIT;