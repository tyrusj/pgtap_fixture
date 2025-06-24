-- Deploy dream-db-extension-tests:functions/plan-child-tests-and-fixtures/fixture-must-exist to pg

BEGIN;

create function unit_test.test_func_plan_children__fixture_must_exist()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When planning child tests and fixtures, if the given fixture does not exist, then the database shall throw
an exception.
$test_description$;
declare fixture_id_not_exists integer;
declare fixture_id_exists integer;
begin
    -- Add fixtures
    insert into fixture ("name")
    values ('my_fixture_A')
    returning id into fixture_id_exists
    ;

    insert into fixture ("name")
    values ('my_fixture_B')
    returning id into fixture_id_not_exists
    ;

    -- Delete a fixture, which guarantees that it won't exist.
    delete from fixture
    where id = fixture_id_not_exists
    ;

    -- Execute the scenarios

    return query select tap.throws_ok(
        format($throws$
            select _plan_child_tests_and_fixtures(%s)
        $throws$, fixture_id_not_exists),
        null,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$1: Plan a fixture that doesn't exist. Expect an exception.$scenario$)
    );

    return query select tap.lives_ok(
        format($lives$
            select _plan_child_tests_and_fixtures(%s)
        $lives$, fixture_id_exists),
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$2: Plan a fixture that exists. Expect no exception.$scenario$)
    );

end;
$$;

COMMIT;
