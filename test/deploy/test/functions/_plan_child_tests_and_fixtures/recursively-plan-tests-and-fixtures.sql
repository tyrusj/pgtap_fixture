-- Deploy dream-db-extension-tests:functions/plan-child-tests-and-fixtures/recursively-plan-tests-and-fixtures to pg

BEGIN;

create function unit_test.test_func_plan_children__recursively_plan()
returns setof text
language plpgsql
as
$$
declare test_description text :=$description$
When planning child tests and fixtures, for the given fixture, for each (child) fixture whose parent fixture
is that fixture, the function shall include child tests and fixtures of that fixture in the plan.
$description$;
declare root_fixture_id integer;
declare child_fixture_id integer;
declare child_child_fixture_A_id integer;
declare child_child_fixture_B_id integer;
declare test_id_A integer;
declare test_id_B integer;
declare test_id_C integer;
declare test_id_D integer;
declare test_id_E integer;
declare test_id_F integer;
declare test_id_G integer;
declare test_id_H integer;
begin

    -- Create several generations of fixtures
    insert into fixture ("name") values ('my_fixture_A') returning id into root_fixture_id;
    insert into fixture ("name", "parent_fixture_id") values ('my_fixture_B', root_fixture_id) returning id into child_fixture_id;
    insert into fixture ("name", "parent_fixture_id") values ('my_fixture_C', child_fixture_id) returning id into child_child_fixture_A_id;
    insert into fixture ("name", "parent_fixture_id") values ('my_fixture_D', child_fixture_id) returning id into child_child_fixture_B_id;

    -- Create tests in all of the fixtures
    insert into test ("schema", "function", "parent_fixture_id") values ('my_schema', 'my_function_1', root_fixture_id) returning id into test_id_A;
    insert into test ("schema", "function", "parent_fixture_id") values ('my_schema', 'my_function_2', root_fixture_id) returning id into test_id_B;
    insert into test ("schema", "function", "parent_fixture_id") values ('my_schema', 'my_function_3', child_fixture_id) returning id into test_id_C;
    insert into test ("schema", "function", "parent_fixture_id") values ('my_schema', 'my_function_4', child_fixture_id) returning id into test_id_D;
    insert into test ("schema", "function", "parent_fixture_id") values ('my_schema', 'my_function_5', child_child_fixture_A_id) returning id into test_id_E;
    insert into test ("schema", "function", "parent_fixture_id") values ('my_schema', 'my_function_6', child_child_fixture_A_id) returning id into test_id_F;
    insert into test ("schema", "function", "parent_fixture_id") values ('my_schema', 'my_function_7', child_child_fixture_B_id) returning id into test_id_G;
    insert into test ("schema", "function", "parent_fixture_id") values ('my_schema', 'my_function_8', child_child_fixture_B_id) returning id into test_id_H;

    -- Create tables that contain the expected results
    create temp table _fixture_plan_expected as select v.id from (values (child_fixture_id), (child_child_fixture_A_id), (child_child_fixture_B_id)) as v(id);
    create temp table _test_plan_expected as select v.id from (values (test_id_A), (test_id_B), (test_id_C), (test_id_D), (test_id_E), (test_id_F), (test_id_G), (test_id_H)) as v(id);

    perform _plan_child_tests_and_fixtures(root_fixture_id);
    return query select tap.set_eq(
        'select id from fixture_plan',
        'select id from _fixture_plan_expected',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$1: Expect the fixture plan to contain all of the child fixtures recursively.$scenario$)
    );
    return query select tap.set_eq(
        'select id from test_plan',
        'select id from _test_plan_expected',
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$1: Expect the test plan to contain all of the tests in the child fixtures recursively.$scenario$)
    );

end;
$$;

COMMIT;
