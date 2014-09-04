DROP INDEX IF EXISTS idx_listcomptegenaux_<cloture> ;

CREATE INDEX idx_listcomptegenaux_<cloture>  ON listcomptegenaux_<cloture>  USING btree (num_cpte_gen_aux, lib_cpte_gen_aux) ;

