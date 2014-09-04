DROP INDEX IF EXISTS idx_num_ecr_fec_<cloture>;
-- Index permettant l'affichage de l'onglet journal ainsi que les filtres sur les dates comptables
CREATE INDEX idx_num_ecr_fec_<cloture>   ON fec_<cloture> USING btree  (num_ecr);
