DROP TABLE IF EXISTS  panier_dir CASCADE;
DROP TABLE IF EXISTS  panier_axe CASCADE;
DROP TABLE IF EXISTS  panier_ligne CASCADE;
DROP SEQUENCE IF EXISTS   panier_dir_id_panier_dir ;
DROP SEQUENCE IF EXISTS   panier_axe_id_panier_axe ;

CREATE SEQUENCE panier_dir_id_panier_dir
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;

CREATE SEQUENCE  panier_axe_id_panier_axe
  INCREMENT 1
  MINVALUE 1
  MAXVALUE 9223372036854775807
  START 1
  CACHE 1;

-- Tables du panier
 
CREATE TABLE panier_dir (
  id_panier_dir serial NOT NULL,
  id_parent integer,
  lib_dir text,
  CONSTRAINT pk_panier_dir PRIMARY KEY (id_panier_dir ));

CREATE TABLE panier_axe (
  id_panier_dir integer NOT NULL,
  lib_axe text NOT NULL,
  id_panier_axe serial NOT NULL,
  lib_comment text,
  CONSTRAINT pk_panier_axe PRIMARY KEY (id_panier_axe ),
  CONSTRAINT fk_panier_axe FOREIGN KEY (id_panier_dir)
      REFERENCES panier_dir (id_panier_dir));

CREATE TABLE panier_ligne (
  exercice date NOT NULL,
  id_panier_axe integer NOT NULL,
  id_ligne integer NOT NULL,
  CONSTRAINT fk_panier_ligne_axe FOREIGN KEY (id_panier_axe)
      REFERENCES panier_axe (id_panier_axe),
  CONSTRAINT fk_panier_ligne_cloture FOREIGN KEY (exercice)
      REFERENCES exercice (date_cloture));