-- Deploy dream-db-provision:set-deploy-privs to pg

BEGIN;

grant all on database deploy_debug to nonadmin;

COMMIT;
