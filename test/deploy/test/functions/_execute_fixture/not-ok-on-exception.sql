-- Deploy dream-db-extension-tests:test/functions/_execute_fixture/not-ok-on-exception to pg

BEGIN;

create function unit_test.test_func_execute_fixture__not_ok_on_exception()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When executing a fixture, if the fixture is not empty, and if the fixture throws an exception,
then function shall set the fixture's status to 'not ok'.
$test_description$;
declare fixture_id_a integer;
declare fixture_id_b integer;
begin

    -- create fixtures
    insert into fixture ("name", "description", "shutdown")
    values (
        'fixture_a',
        'description_a',
        $shutdown$raise 'Shutdown exception.';$shutdown$
    ) returning id into fixture_id_a;
    insert into fixture ("name", "parent_fixture_id") values ('fixture_b', fixture_id_a) returning id into fixture_id_b;

    -- add fixtures to plan
    insert into fixture_plan ("id") values (fixture_id_a), (fixture_id_b);

    perform _execute_fixture(fixture_id_a, 1);
    return query select tap.results_eq(
        format('select ok from fixture_plan where id = %s', fixture_id_a),
        $want$values (false)$want$,
        test_description
    );

end;
$$;

COMMIT;
