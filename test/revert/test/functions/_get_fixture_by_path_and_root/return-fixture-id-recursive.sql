-- Revert dream-db-extension-tests:functions/_get_fixture_by_path_and_root/return-fixture-id-recursive from pg

BEGIN;

drop function unit_test.test_func_get_fixture__return_fixture_id_recursive();

COMMIT;
