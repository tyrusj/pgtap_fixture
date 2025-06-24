-- Deploy dream-db-extension-tests:functions/execute_tests/plan-given-fixtures to pg

BEGIN;

create function unit_test.test_func_execute_tests__plan_given_fixtures()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When executing tests, if one or more fixtures are given, for each given fixture, the function shall plan
that fixture.
$test_description$;
declare fixture_id_a integer;
declare fixture_id_b integer;
declare fixture_id_c integer;
declare fixture_id_d integer;
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

    -- Stub _plan_parent_fixtures, since we don't want to plan the parent fixtures in this test.
    alter function _plan_parent_fixtures(fixtureId integer)
    rename to _plan_parent_fixtures___original;
    create function _plan_parent_fixtures(fixtureId integer)
    returns void
    language plpgsql
    as
    $stub$
    begin
        
    end;
    $stub$;

    -- Create fixtures
    insert into fixture ("name") values ('fixture_a') returning id into fixture_id_a;
    insert into fixture ("name") values ('fixture_b') returning id into fixture_id_b;
    insert into fixture ("name", "parent_fixture_id") values ('fixture_c', fixture_id_a) returning id into fixture_id_c;
    insert into fixture ("name", "parent_fixture_id") values ('fixture_d', fixture_id_b) returning id into fixture_id_d;

    perform execute_tests(array['fixture_a'], null::name, null::text[]);
    return query select tap.set_eq(
        'select id from fixture_plan',
        format('values (%s)', fixture_id_a),
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$1: Plan one root fixture.$scenario$)
    );

    delete from fixture_plan;
    perform execute_tests(array['fixture_a', 'fixture_b'], null::name, null::text[]);
    return query select tap.set_eq(
        'select id from fixture_plan',
        format('values (%s), (%s)', fixture_id_a, fixture_id_b),
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$2: Plan two root fixtures.$scenario$)
    );

    delete from fixture_plan;
    perform execute_tests(array['fixture_a/fixture_c'], null::name, null::text[]);
    return query select tap.set_eq(
        'select id from fixture_plan',
        format('values (%s)', fixture_id_c),
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$3: Plan one non-root fixture.$scenario$)
    );

    delete from fixture_plan;
    perform execute_tests(array['fixture_a/fixture_c', 'fixture_b/fixture_d'], null::name, null::text[]);
    return query select tap.set_eq(
        'select id from fixture_plan',
        format('values (%s), (%s)', fixture_id_c, fixture_id_d),
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$2: Plan two non-root fixtures.$scenario$)
    );

end;
$$;

COMMIT;
