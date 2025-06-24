-- Deploy dream-db-extension-tests:functions/_remove_unused_fixtures/remove-given-fixture to pg

BEGIN;

create function unit_test.test_func_unused_fixtures__remove_given_fixture()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When removing unused fixtures, if there are no test records whose parent fixture ID corresponds with
the given fixture ID, and if there are no fixture records whose parent fixture ID corresponds with
the given fixture ID, and if the fixture record that corresponds with the given fixture ID has null
startup, shutdown, setup, and teardown statements, then the function shall remove the record from
the fixture table with that fixture ID.
$test_description$;
declare unused_fixture_id integer;
declare fixture_used_by_test_id integer;
declare fixture_used_by_fixture_id integer;
declare fixture_with_startup_id integer;
declare fixture_with_shutdown_id integer;
declare fixture_with_setup_id integer;
declare fixture_with_teardown_id integer;
begin

    -- Create fixtures
    insert into fixture ("name") values ('unused_fixture') returning id into unused_fixture_id;
    insert into fixture ("name") values ('fixture_used_by_test') returning id into fixture_used_by_test_id;
    insert into fixture ("name") values ('fixture_used_by_fixture') returning id into fixture_used_by_fixture_id;
    insert into fixture ("name", "parent_fixture_id") values ('child_fixture', fixture_used_by_fixture_id);
    insert into fixture ("name", "startup") values ('fixture_with_startup', $code$create temp table my_temp(id integer);$code$) returning id into fixture_with_startup_id;
    insert into fixture ("name", "shutdown") values ('fixture_with_shutdown', $code$create temp table my_temp(id integer);$code$) returning id into fixture_with_shutdown_id;
    insert into fixture ("name", "setup") values ('fixture_with_setup', $code$create temp table my_temp(id integer);$code$) returning id into fixture_with_setup_id;
    insert into fixture ("name", "teardown") values ('fixture_with_teardown', $code$create temp table my_temp(id integer);$code$) returning id into fixture_with_teardown_id;

    -- Create tests
    insert into test ("schema", "function", "parent_fixture_id") values ('my_schema', 'my_function', fixture_used_by_test_id);

    -- Execute the scenarios

    perform _remove_unused_fixtures(unused_fixture_id);
    return query select tap.set_hasnt(
        $have$select id from fixture;$have$,
        format($dontwant$values (%s)$dontwant$, unused_fixture_id),
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$1: The given fixture is unused. Expect it to be removed.$scenario$)
    );

    perform _remove_unused_fixtures(fixture_used_by_test_id);
    return query select tap.set_has(
        $have$select id from fixture;$have$,
        format($want$values (%s)$want$, fixture_used_by_test_id),
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$2: The given fixture is used by a test. Expect it to remain.$scenario$)
    );

    perform _remove_unused_fixtures(fixture_used_by_fixture_id);
    return query select tap.set_has(
        $have$select id from fixture;$have$,
        format($want$values (%s)$want$, fixture_used_by_fixture_id),
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$3: The given fixture is used by another fixture. Expect it to remain.$scenario$)
    );

    perform _remove_unused_fixtures(fixture_with_startup_id);
    return query select tap.set_has(
        $have$select id from fixture;$have$,
        format($want$values (%s)$want$, fixture_with_startup_id),
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$4: The given fixture has a startup statement. Expect it to remain.$scenario$)
    );

    perform _remove_unused_fixtures(fixture_with_shutdown_id);
    return query select tap.set_has(
        $have$select id from fixture;$have$,
        format($want$values (%s)$want$, fixture_with_shutdown_id),
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$5: The given fixture has a shutdown statement. Expect it to remain.$scenario$)
    );

    perform _remove_unused_fixtures(fixture_with_setup_id);
    return query select tap.set_has(
        $have$select id from fixture;$have$,
        format($want$values (%s)$want$, fixture_with_setup_id),
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$6: The given fixture has a setup statement. Expect it to remain.$scenario$)
    );

    perform _remove_unused_fixtures(fixture_with_teardown_id);
    return query select tap.set_has(
        $have$select id from fixture;$have$,
        format($want$values (%s)$want$, fixture_with_teardown_id),
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$7: The given fixture has a teardown statement. Expect it to remain.$scenario$)
    );

end;
$$;

COMMIT;
