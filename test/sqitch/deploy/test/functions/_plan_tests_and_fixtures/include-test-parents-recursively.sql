-- Deploy dream-db-extension-tests:functions/plan-tests-and-fixtures/include-test-parents-recursively to pg

BEGIN;

create function unit_test.test_func_plan__include_test_parents_recursive()
returns setof text
language plpgsql
as
$$
declare test_description text :=$test_description$
When planning tests and fixtures, for each given test, if that test has a parent fixture, then the
function shall recursively plan parent fixtures of that fixture.
$test_description$;
declare fixture_id_A integer;
declare fixture_id_B integer;
declare fixture_id_C integer;
declare fixture_id_D integer;
declare test_id_with_parent_fixture_A integer;
declare test_id_with_parent_fixture_B integer;
declare test_id_with_parent_fixture_C integer;
declare test_id_with_parent_fixture_D integer;
declare test_id_without_parent_fixture_1 integer;
declare test_id_without_parent_fixture_2 integer;
declare test_id_without_parent_fixture_3 integer;
declare test_id_without_parent_fixture_4 integer;
begin

    -- Create the fixtures
    insert into fixture ("name") values ('my_fixture_1') returning id into fixture_id_A;
    insert into fixture ("name") values ('my_fixture_2') returning id into fixture_id_B;
    insert into fixture ("name") values ('my_fixture_3') returning id into fixture_id_C;
    insert into fixture ("name") values ('my_fixture_4') returning id into fixture_id_D;

    -- Create the tests
    insert into test ("schema", "function") values ('my_schema', 'my_function_1') returning id into test_id_without_parent_fixture_1;
    insert into test ("schema", "function") values ('my_schema', 'my_function_2') returning id into test_id_without_parent_fixture_2;
    insert into test ("schema", "function") values ('my_schema', 'my_function_3') returning id into test_id_without_parent_fixture_3;
    insert into test ("schema", "function") values ('my_schema', 'my_function_4') returning id into test_id_without_parent_fixture_4;
    insert into test ("schema", "function", "parent_fixture_id") values ('my_schema', 'my_function_5', fixture_id_A) returning id into test_id_with_parent_fixture_A;
    insert into test ("schema", "function", "parent_fixture_id") values ('my_schema', 'my_function_6', fixture_id_B) returning id into test_id_with_parent_fixture_B;
    insert into test ("schema", "function", "parent_fixture_id") values ('my_schema', 'my_function_7', fixture_id_C) returning id into test_id_with_parent_fixture_C;
    insert into test ("schema", "function", "parent_fixture_id") values ('my_schema', 'my_function_8', fixture_id_D) returning id into test_id_with_parent_fixture_D;

    -- Create table to capture the calls to _plan_parent_fixtures
    create temp table _plan_parent_fixtures_call (fixtureId integer);

    -- Mock _plan_parent_fixtures
    alter function _plan_parent_fixtures(fixtureId integer)
    rename to _plan_parent_fixtures___original;
    create function _plan_parent_fixtures(fixtureId integer)
    returns void
    language sql
    begin atomic
        insert into _plan_parent_fixtures_call (fixtureId) values (fixtureId);
    end;

    perform _plan_tests_and_fixtures(null, array[test_id_with_parent_fixture_A]);
    return query select tap.set_has(
        'select fixtureId from _plan_parent_fixtures_call',
        format('select v.id from (values (%s)) as v(id)', fixture_id_A),
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$1: Plan one test with a parent fixture. Expect the _plan_parent_fixtures function to be called with the parent fixture.$scenario$)
    );

    delete from _plan_parent_fixtures_call;
    perform _plan_tests_and_fixtures(null, array[test_id_without_parent_fixture_1]);
    return query select tap.is_empty(
        'select fixtureId from _plan_parent_fixtures_call',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$2: Plan one test without a parent fixture. Expect the _plan_parent_fixture function to not be called.$scenario$)
    );

    delete from _plan_parent_fixtures_call;
    perform _plan_tests_and_fixtures(null, array[test_id_with_parent_fixture_B, test_id_with_parent_fixture_C]);
    return query select tap.set_has(
        'select fixtureId from _plan_parent_fixtures_call',
        format('select v.id from (values (%s), (%s)) as v(id)', fixture_id_B, fixture_id_C),
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$3: Plan two tests with parent fixtures. Expect the _plan_parent_fixtures function to be called with the parent fixtures.$scenario$)
    );

    delete from _plan_parent_fixtures_call;
    perform _plan_tests_and_fixtures(null, array[test_id_without_parent_fixture_2, test_id_without_parent_fixture_3]);
    return query select tap.is_empty(
        'select fixtureId from _plan_parent_fixtures_call',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$4: Plan two tests without parent fixtures. Expect the _plan_parent_fixtures function to not be called.$scenario$)
    );

    delete from _plan_parent_fixtures_call;
    perform _plan_tests_and_fixtures(null, array[test_id_without_parent_fixture_4, test_id_with_parent_fixture_D]);
    return query select tap.set_has(
        'select fixtureId from _plan_parent_fixtures_call',
        format('select v.id from (values (%s)) as v(id)', fixture_id_D),
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$5: Plan two tests, one with a parent fixture and one without. Expect the _plan_parent_fixtures function to be called with the parent fixture.$scenario$)
    );

    delete from _plan_parent_fixtures_call;
    perform _plan_tests_and_fixtures(null, array[]::integer[]);
    return query select tap.is_empty(
        'select fixtureId from _plan_parent_fixtures_call',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$6: Plan an empty array of tests. Expect the _plan_parent_fixtures function to not be called.$scenario$)
    );

    delete from _plan_parent_fixtures_call;
    perform _plan_tests_and_fixtures(null, null);
    return query select tap.is_empty(
        'select fixtureId from _plan_parent_fixtures_call',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$7: Plan a null array of tests. Expect the _plan_parent_fixtures function to not be called.$scenario$)
    );
    
end;
$$;

COMMIT;
