--------------------------------------------------------------------------
-- This script updates CP tables from an USBR HDB 5.2 CCP Schema to 
-- OpenDCS 6.2 Schema.
--
-- Important!!! This script should be executed as schema user that owns the CP tables.
-- Also: Edit the file defines.sql before executing this script and make 
-- sure CP_OWNER is set correctly.
-- Execute this script in the same directory that contains defines.sql
--------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- This software was written by Cove Software, LLC ("COVE") under contract 
-- to the United States Government. 
-- No warranty is provided or implied other than specific contractual terms
-- between COVE and the U.S. Government
-- 
-- Copyright 2016 U.S. Government.
-----------------------------------------------------------------------------
set echo on
spool combined.log
    
whenever sqlerror continue
set define on
@@defines.sql

----------- snip
--undefine TBL_SPACE_SPEC;
--define TBL_SPACE_SPEC = 'tablespace HDB_DATA'
--
--undefine IDX_TBL_SPACE_SPEC;
--define IDX_TBL_SPACE_SPEC = 'tablespace HDB_IDX'
--
--define DECODES_OWNER;
--define DECODES_OWNER = 'DECODES'
--
--undefine CP_OWNER;
--define CP_OWNER = 'ECODBA'
----------- snip





ALTER TABLE CP_ALGORITHM MODIFY(EXEC_CLASS VARCHAR2(240 BYTE));

ALTER TABLE CP_ALGO_PROPERTY MODIFY(PROP_VALUE  NULL);

ALTER TABLE TSDB_DATABASE_VERSION RENAME COLUMN VERSION TO DB_VERSION;

UPDATE TSDB_GROUP_MEMBER_GROUP SET INCLUDE_GROUP = 'A' WHERE INCLUDE_GROUP IS NULL;
ALTER TABLE TSDB_GROUP_MEMBER_GROUP MODIFY(INCLUDE_GROUP VARCHAR2(1 BYTE) NOT NULL);

ALTER TABLE TSDB_GROUP_MEMBER_OTHER MODIFY(MEMBER_VALUE VARCHAR2(240 BYTE));
ALTER TABLE TSDB_GROUP_MEMBER_TS RENAME COLUMN data_id TO TS_ID;

ALTER TABLE CP_COMP_PROC_LOCK RENAME COLUMN HOST TO HOSTNAME;

ALTER TABLE CP_COMP_TS_PARM RENAME COLUMN INTERVAL TO INTERVAL_ABBR;
ALTER TABLE CP_COMP_TS_PARM MODIFY(TABLE_SELECTOR VARCHAR2(240 BYTE));

ALTER TABLE CP_COMP_TS_PARM MODIFY(DELTA_T NOT NULL);
ALTER TABLE CP_COMP_TS_PARM ADD(SITE_ID NUMBER(*,0));

DROP INDEX CP_COMP_TASKLIST_IDX_APP;
CREATE UNIQUE INDEX CP_COMP_TASKLIST_IDX_APP ON CP_COMP_TASKLIST
(LOADING_APPLICATION_ID, RECORD_NUM) &IDX_TBL_SPACE_SPEC;


ALTER TABLE CP_COMP_DEPENDS_SCRATCHPAD
 ADD CONSTRAINT CP_COMP_DEPENDS_SCRATCHPAD_FK
  FOREIGN KEY (COMPUTATION_ID)
  REFERENCES CP_COMPUTATION (COMPUTATION_ID);

update CP_COMPUTATION set GROUP_ID = null where GROUP_ID = -1;

ALTER TABLE CP_COMPUTATION
 ADD CONSTRAINT CP_COMPUTATION_FKGR
  FOREIGN KEY (GROUP_ID)
  REFERENCES TSDB_GROUP (GROUP_ID);
  
CREATE TABLE CP_ALGO_SCRIPT
(
	ALGORITHM_ID NUMBER(*,0) NOT NULL,
	SCRIPT_TYPE CHAR NOT NULL,
	BLOCK_NUM NUMBER(4,0) NOT NULL,
	SCRIPT_DATA VARCHAR2(4000) NOT NULL,
	PRIMARY KEY (ALGORITHM_ID, SCRIPT_TYPE, BLOCK_NUM)
) &TBL_SPACE_SPEC;

ALTER TABLE CP_ALGO_SCRIPT
    ADD CONSTRAINT CP_ALGO_SCRIPT_FK
    FOREIGN KEY (ALGORITHM_ID)
    REFERENCES CP_ALGORITHM (ALGORITHM_ID)
;
 
GRANT SELECT,INSERT,UPDATE,DELETE ON CP_ALGO_SCRIPT TO CALC_DEFINITION_ROLE;
CREATE PUBLIC SYNONYM CP_ALGO_SCRIPT FOR &CP_OWNER..CP_ALGO_SCRIPT;

GRANT SELECT,INSERT,UPDATE,DELETE ON DECODES_SITE_EXT TO CALC_DEFINITION_ROLE;
CREATE PUBLIC SYNONYM DECODES_SITE_EXT FOR &CP_OWNER..DECODES_SITE_EXT;


GRANT REFERENCES ON HDB_LOADING_APPLICATION TO &DECODES_OWNER;


spool off
exit;