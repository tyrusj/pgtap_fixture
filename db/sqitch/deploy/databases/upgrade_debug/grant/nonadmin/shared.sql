-- Deploy dream-db-provision:set-deploy-privs to pg

BEGIN;

grant all on database upgrade_debug to nonadmin;

COMMIT;
