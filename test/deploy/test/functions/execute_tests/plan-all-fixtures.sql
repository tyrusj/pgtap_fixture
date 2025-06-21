-- Deploy dream-db-extension-tests:functions/execute_tests/plan-all-fixtures to pg

BEGIN;

create function unit_test.test_func_execute_tests__plan_all_fixtures()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When executing tests, if no fixtures or tests are given, then for each record in the fixture table that
does not have a parent fixture ID, the function shall plan that fixture.
$test_description$;
declare fixture_id_no_parent_a integer;
declare fixture_id_no_parent_b integer;
declare fixture_id_child_c integer;
declare fixture_id_child_d integer;
begin

    -- Stub _plan_child_tests_and_fixtures, since we don't want to plan the child fixtures in this test.
    alter function _plan_child_tests_and_fixtures(fixtureId integer)
    rename to _plan_child_tests_and_fixtures___original;
    create function _plan_child_tests_and_fixtures(fixtureId integer)
    returns void
    language plpgsql
    as
    $stub$
    begin
        
    end;
    $stub$;

    -- Create fixtures
    insert into fixture ("name") values ('no_parent_a') returning id into fixture_id_no_parent_a;
    insert into fixture ("name") values ('no_parent_b') returning id into fixture_id_no_parent_b;
    insert into fixture ("name", "parent_fixture_id") values ('child_c', fixture_id_no_parent_a) returning id into fixture_id_child_c;
    insert into fixture ("name", "parent_fixture_id") values ('child_d', fixture_id_no_parent_b) returning id into fixture_id_child_d;

    perform execute_tests(null::text[], null::name, null::text[]);
    return query select tap.set_eq(
        'select id from fixture_plan',
        format('values (%s), (%s)', fixture_id_no_parent_a, fixture_id_no_parent_b),
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$1: Execute tests with null test and fixtures arrays.$scenario$)
    );

    perform execute_tests('{}'::text[], null::name, '{}'::text[]);
    return query select tap.set_eq(
        'select id from fixture_plan',
        format('values (%s), (%s)', fixture_id_no_parent_a, fixture_id_no_parent_b),
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$2: Execute tests with empty test and fixtures arrays.$scenario$)
    );

end;
$$;

COMMIT;
