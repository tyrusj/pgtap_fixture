-- Deploy dream-db-extension-tests:test/functions/_execute_fixture/return-result to pg

BEGIN;

create function unit_test.test_func_execute_fixture__return_result()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When executing a fixture, if the fixture is not empty, then the function shall return a formatted
result, where the result name is the fixture path, the result description is the fixture description,
and the result status is the fixture status.
$test_description$;
declare fixture_id_a integer;
declare fixture_id_b integer;
declare fixture_id_c integer;
begin

    -- Create fixtures
    insert into fixture ("name") values ('fixture_a') returning id into fixture_id_a;
    insert into fixture ("name", "parent_fixture_id", "description") values ('fixture_b', fixture_id_a, 'description b') returning id into fixture_id_b;
    insert into fixture ("name", "parent_fixture_id") values ('fixture_c', fixture_id_b) returning id into fixture_id_c;

    -- Add fixtures to the plan
    insert into fixture_plan ("id") values (fixture_id_b), (fixture_id_c);

    return query select tap.set_has(
        format('select _execute_fixture(%s, 8)', fixture_id_b),
        $want$values ('ok 8 - fixture_a/fixture_b description b')$want$,
        test_description
    );

end;
$$;

COMMIT;
