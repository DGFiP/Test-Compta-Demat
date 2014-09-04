DROP INDEX IF EXISTS idx_num_ecr_ecriture_<cloture>  ;
DROP INDEX IF EXISTS idx_date_ecriture_<cloture>;
DROP INDEX IF EXISTS idx_jrn_ecriture_<cloture> ;
DROP INDEX IF EXISTS idx_tva_ecriture_<cloture> ;
DROP INDEX IF EXISTS idx_ecr_type_ecriture_<cloture> ;
commit ;

CREATE INDEX idx_num_ecr_ecriture_<cloture> 	ON ecriture_<cloture> USING btree(num_ecr);
commit ;
CREATE INDEX idx_date_ecriture_<cloture> 		ON ecriture_<cloture> USING btree(date_cpt);
commit ;
CREATE INDEX idx_jrn_ecriture_<cloture> 		ON ecriture_<cloture> USING btree(code_jrnal, lib_jrnal);
commit ;
CREATE INDEX idx_tva_ecriture_<cloture> 		ON ecriture_<cloture> USING btree(taux_tva);
commit ;
CREATE INDEX idx_ecr_type_ecriture_<cloture> 	ON ecriture_<cloture> (ecr_type) WHERE ecr_type != 0;
