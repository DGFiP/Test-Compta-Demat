DROP TABLE IF EXISTS EXERCICE;

CREATE TABLE EXERCICE
(
  DATE_CLOTURE	Date NOT NULL,
  CONSTRAINT PK_EXERCICE PRIMARY KEY(DATE_CLOTURE)
);

CREATE OR REPLACE FUNCTION unaccent_string(text)
RETURNS text IMMUTABLE STRICT LANGUAGE SQL
AS $$ SELECT translate(
    $1,
    'âãäåÁÂÃÄÅèééêëÈÉÉÊËìíîïìÌÍÎÏÌóôõöÒÓÔÕÖùúûüÙÚÛÜÿ',
    'aaaaAAAAAeeeeeEEEEEiiiiiIIIIIooooOOOOOuuuuUUUUy'
); $$;
