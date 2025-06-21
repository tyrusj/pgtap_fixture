-- Deploy dream-db-extension-tests:functions/_execute_fixture/fixture-must-exist to pg

BEGIN;

create function unit_test.test_func_execute_fixture__fixture_must_exist()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When executing a fixture, if the given fixture does not exist, then the function shall throw an exception.
$test_description$;
declare fixture_id_exists integer;
declare fixture_id_not_exists integer;
begin

    -- Create the fixture
    insert into fixture ("name") values ('my_fixture_a') returning id into fixture_id_exists;
    insert into fixture ("name") values ('my_fixture_b') returning id into fixture_id_not_exists;

    -- Delete the fixture that should not exist
    delete from fixture where id = fixture_id_not_exists;

    -- Execute the scenarios

    return query select tap.lives_ok(
        format('select _execute_fixture(%s, 1);', fixture_id_exists),
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$1: Execute a fixture that exists. Expect no exception.$scenario$)
    );

    return query select tap.throws_ok(
        format('select _execute_fixture(%s, 1);', fixture_id_not_exists),
        null,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$2: Execute a fixture that does not exist. Expect an exception.$scenario$)
    );

end;
$$;

COMMIT;

