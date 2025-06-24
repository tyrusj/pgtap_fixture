-- Deploy dream-db-extension-tests:functions/plan-tests-and-fixtures/include-fixtures-recursively to pg

BEGIN;

create function unit_test.test_func_plan__include_fixtures_recursive()
returns setof text
language plpgsql
as
$$
declare test_description text :=$test_description$
When planning tests and fixtures, for each given fixture, the function shall recursively plan parent
fixtures of that fixture.
$test_description$;
declare fixture_id_A integer;
declare fixture_id_B integer;
declare fixture_id_C integer;
begin

    -- Create the fixtures
    insert into fixture ("name") values ('my_fixture_1') returning id into fixture_id_A;
    insert into fixture ("name") values ('my_fixture_2') returning id into fixture_id_B;
    insert into fixture ("name") values ('my_fixture_3') returning id into fixture_id_C;

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

    -- Execute the scenarios

    delete from _plan_parent_fixtures_call;
    perform _plan_tests_and_fixtures(array[fixture_id_A], null);
    return query select tap.set_has(
        'select fixtureId from _plan_parent_fixtures_call',
        format('select v.id from (values (%s)) as v(id)', fixture_id_A),
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$1: Plan one fixture. Expect _plan_parent_fixtures to be called with that fixture.$scenario$)
    );

    delete from _plan_parent_fixtures_call;
    perform _plan_tests_and_fixtures(array[fixture_id_B, fixture_id_C], null);
    return query select tap.set_has(
        'select fixtureId from _plan_parent_fixtures_call',
        format('select v.id from (values (%s), (%s)) as v(id)', fixture_id_B, fixture_id_C),
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$2: Plan two fixtures. Expect _plan_parent_fixtures to be called with those fixtures.$scenario$)
    );

    delete from _plan_parent_fixtures_call;
    perform _plan_tests_and_fixtures(array[]::integer[], null);
    return query select tap.is_empty(
        'select fixtureId from _plan_parent_fixtures_call',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$3: Plan an empty array of fixtures. Expect _plan_parent_fixtures to not be called.$scenario$)
    );

    delete from _plan_parent_fixtures_call;
    perform _plan_tests_and_fixtures(null, null);
    return query select tap.is_empty(
        'select fixtureId from _plan_parent_fixtures_call',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$4: Plan a null array of fixtures. Expect _plan_parent_fixtures to not be called.$scenario$)
    );

end;
$$;

COMMIT;
