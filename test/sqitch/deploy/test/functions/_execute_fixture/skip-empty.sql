-- Deploy dream-db-extension-tests:test/functions/_execute_fixture/skip-empty to pg

BEGIN;

create function unit_test.test_func_execute_fixture__skip_empty()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When executing a fixture, if the fixture contains no tests or child fixtures, then the function
shall return a formatted skipped test, where the name is the fixture path, the description is
the fixture description, the reason is 'Fixture is empty.', and the status is 'ok'.
$test_description$;
declare fixture_id_a integer;
declare fixture_id_b integer;
declare fixture_id_c integer;
begin

    -- create fixtures
    insert into fixture ("name") values ('path') returning id into fixture_id_a;
    insert into fixture ("name", "parent_fixture_id") values ('to', fixture_id_a) returning id into fixture_id_b;
    insert into fixture ("name", "parent_fixture_id", "description") values ('fixture', fixture_id_b, 'description') returning id into fixture_id_c;

    -- add fixture to plan
    insert into fixture_plan ("id") values (fixture_id_c);

    return query select tap.set_has(
        format('select _execute_fixture(%s, 1)', fixture_id_c),
        $want$values ('ok 1 - path/to/fixture description # skip Fixture is empty.')$want$,
        test_description
    );

end;
$$;

COMMIT;
