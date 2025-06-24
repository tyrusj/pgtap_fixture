-- Deploy dream-db-extension-tests:test/functions/_execute_fixture/return-subtest to pg

BEGIN;

create function unit_test.test_func_execute_fixture__return_subtest()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When executing a fixture, if the fixture is not empty, then the function shall return a formatted
subtest, where the subtest name is the fixture path, and the subtest description is the fixture
description.
$test_description$;
declare fixture_id_a integer;
declare fixture_id_b integer;
declare fixture_id_c integer;
begin

    -- create fixtures
    insert into fixture ("name") values ('fixture_a') returning id into fixture_id_a;
    insert into fixture ("name", "description", "parent_fixture_id") values ('fixture_b', 'description_b', fixture_id_a) returning id into fixture_id_b;
    insert into fixture ("name", "parent_fixture_id") values ('fixture_c', fixture_id_b)  returning id into fixture_id_c;

    -- add fixtures to plan
    insert into fixture_plan ("id") values (fixture_id_b), (fixture_id_c);

    return query select tap.set_has(
        format('select _execute_fixture(%s, 1)', fixture_id_b),
        $want$values ('# Subtest: fixture_a/fixture_b description_b')$want$,
        test_description
    );

end;
$$;

COMMIT;
