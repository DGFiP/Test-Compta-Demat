 DROP TABLE IF EXISTS LIASSE CASCADE;
 DROP TABLE IF EXISTS ca3 CASCADE;

 
 CREATE TABLE liasse (liasse text, code text, cloture date, valeur text,CONSTRAINT pk_liasse PRIMARY KEY (liasse, code, cloture) );

 CREATE TABLE ca3 (annee int, mois int, code text, valeur text, CONSTRAINT pk_ca3 PRIMARY KEY (annee, mois, code));