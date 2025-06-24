-- Deploy dream-db-extension-tests:functions/execute_tests/execute-root-fixtures to pg

BEGIN;

create function unit_test.test_func_execute_tests__execute_root_fixtures()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When executing tests, for each fixture in the plan that does not have a parent fixture, the function shall
execute that fixture.
$test_description$;
declare fixture_id_a integer;
declare fixture_id_b integer;
declare fixture_id_c integer;
declare fixture_id_d integer;
begin

    -- Stub _function_rollback so that we can see what was executed.
    alter function _function_rollback()
    rename to _function_rollback___original;
    create function _function_rollback()
    returns void
    language plpgsql
    as
    $stub$
    begin

    end;
    $stub$;

    -- Create a table to track which fixtures are executed.
    create temp table executed_fixture (id text);

    -- Create fixtures
    insert into fixture ("name", "startup") values ('my_fixture_a', $startup$insert into executed_fixture ("id") values ('a');$startup$) returning id into fixture_id_a;
    insert into fixture ("name", "startup") values ('my_fixture_b', $startup$insert into executed_fixture ("id") values ('b');$startup$) returning id into fixture_id_b;
    insert into fixture ("name", "startup") values ('my_fixture_c', $startup$insert into executed_fixture ("id") values ('c');$startup$) returning id into fixture_id_c;
    insert into fixture ("name", "parent_fixture_id") values ('my_fixture_d', fixture_id_c) returning id into fixture_id_d;
    insert into fixture ("name", "parent_fixture_id") values ('my_fixture_e', fixture_id_a);

    -- Create a test
    insert into test ("schema", "function", "parent_fixture_id") values ('my_schema', 'my_function', fixture_id_b);

    -- Execute the scenarios

    perform execute_tests(array['my_fixture_a', 'my_fixture_c/my_fixture_d'], 'my_schema', array['my_function']);
    return query select tap.set_eq(
        'select id from executed_fixture',
        $eq$values ('a'), ('b'), ('c')$eq$,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$1: Execute a root fixture, a non-root fixture, and a non-root test. Expect _execute_fixture to only be called on the root fixtures.$scenario$)
    );

end;
$$;

COMMIT;
