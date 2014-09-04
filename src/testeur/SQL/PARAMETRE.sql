 DROP TABLE IF EXISTS parametre CASCADE;

CREATE TABLE parametre(id text NOT NULL, valeur text, CONSTRAINT pk_parametre PRIMARY KEY (id)) ;
INSERT INTO parametre(id, valeur) VALUES ('ready', 'false') ;
INSERT INTO parametre(id, valeur) VALUES ('version', '<version>') ;
--INSERT INTO parametre(id, valeur) VALUES ('plan_compte', 'PCG') ;
INSERT INTO parametre(id, valeur) VALUES ('clause_tva', '<clause_tva>') ;
INSERT INTO parametre(id, valeur) VALUES ('societe', '<nomsoc>') ;
