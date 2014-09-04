 DROP TABLE if exists ecriture_<cloture> cascade ;

CREATE TABLE ecriture_<cloture> (
	num_ecr text NOT NULL,
	date_cpt date NOT NULL,
	code_jrnal text DEFAULT '',
	idem_codejrnal boolean,    
	idem_debcre boolean, 
	idem_datecpt boolean, 
	idem_numpiece boolean,
	idem_datepiece boolean, -- 
	idem_codelet boolean , -- 
	lib_jrnal text DEFAULT '',
	lib_ecriture text[],
	date_piece date,
	num_piece text DEFAULT '',
	code_lettrage text,
	nb_ligne integer,
	taux_tva numeric,
	ecr_type int DEFAULT 0,
	sum_debit numeric,
	sum_credit numeric,
	CONSTRAINT pk_ecriture_<cloture> PRIMARY KEY (num_ecr));



commit ;


INSERT INTO ecriture_<cloture>
   SELECT num_ecr, min(date_cpt), min(code_jrnal),
   min(code_jrnal)=max(code_jrnal),
   sum(mtn_debit) = sum(mtn_credit),
   min(date_cpt) = max(date_cpt),
   min(num_piece) = max(num_piece),
   min(date_piece) = max(date_piece),
   min(code_lettrage) = max(code_lettrage),
   min(lib_jrnal), array_agg(distinct lib_ecriture), min(date_piece), min(num_piece), min(code_lettrage), count(*),
   round (CASE WHEN sum(CASE WHEN <clause_tva> THEN mtn_credit-mtn_debit ELSE 0.0 END) > 0.0 THEN
   CASE WHEN sum(CASE WHEN NOT <clause_tva> THEN mtn_credit ELSE 0.0 END) != 0.0 THEN
   sum(CASE WHEN <clause_tva> THEN mtn_credit-mtn_debit ELSE 0.0 END) * 100 /
   sum(CASE WHEN NOT <clause_tva> THEN mtn_credit ELSE 0.0 END)
   ELSE 0.0 END
   WHEN sum(CASE WHEN <clause_tva> THEN mtn_credit-mtn_debit ELSE 0.0 END) < 0.0 THEN
   CASE WHEN sum(CASE WHEN NOT <clause_tva> THEN mtn_debit ELSE 0.0 END) != 0.0 THEN
   -sum(CASE WHEN <clause_tva> THEN mtn_debit-mtn_credit ELSE 0.0 END) * 100 /
   sum(CASE WHEN NOT <clause_tva> THEN mtn_debit ELSE 0.0 END)
   ELSE 0.0 END ELSE 0.0 END, 1), min(ecr_type), sum(mtn_debit), sum(mtn_credit) 
   FROM fec_<cloture> GROUP BY num_ecr ;

