-- Deploy dream-db-extension-tests:functions/_execute_test/rollback-on-exception to pg

BEGIN;

create function unit_test.test_func_execute_test__rollback_on_exception()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When executing a test with data, for each record in the test data table that corresponds with the given test,
if the test throws an exception, then the database shall rollback changes made by the test and its parent
fixture setup.
$test_description$;
declare test_id integer;
declare fixture_id integer;
begin

    -- Stub pg_tap functions that can interfere with tests.
    alter function pgtap__cleanup()
    rename to pgtap__cleanup___original;
    create function pgtap__cleanup()
    returns boolean
    language plpgsql
    as
    $stub$
    begin
        return null;
    end;
    $stub$;

    alter function pgtap_no_plan()
    rename to pgtap_no_plan___original;
    create function pgtap_no_plan()
    returns setof boolean
    language plpgsql
    as
    $stub$
    begin
        
    end;
    $stub$;

    alter function pgtap__restart_numb_seq()
    rename to  pgtap__restart_numb_seq___original;
    create function pgtap__restart_numb_seq()
    returns void
    language plpgsql
    as
    $stub$
    begin

    end;
    $stub$;

    -- Create a table that the function will modify.
    create temp table modified_table (value text);

    -- Create a test function
    create function pg_temp.my_test_function_a(parameters jsonb, testDescription text)
    returns setof text
    language plpgsql
    as
    $test$
    begin
        insert into modified_table ("value") values ('test function modification');
        raise 'my_test_function_a exception';
    end;
    $test$
    ;

    -- Create a fixture record
    insert into fixture ("name", "setup") values ('my_fixture', $setup$insert into modified_table ("value") values ('fixture setup modification');$setup$) returning id into fixture_id;

    -- Create a test record
    insert into test ("schema", "function", "parent_fixture_id") values ('pg_temp', 'my_test_function_a', fixture_id) returning id into test_id;

    -- Create a test data record
    insert into test_data ("test_id") values (test_id);

    -- Plan the test
    insert into test_plan ("id") values (test_id);

    -- Execute the scenarios

    perform _execute_test(test_id, 1);
    return query select tap.set_hasnt(
        'select value from modified_table;',
        $hasnt$select 'test function modification'$hasnt$,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$1: Expect changes made by the test function to be rolled back.$scenario$)
    );
    return query select tap.set_hasnt(
        'select value from modified_table;',
        $hasnt$select 'fixture setup modification'$hasnt$,
        format(E'%s\ntest_scenario: %s', test_description,
        $scenario$2: Expect changes made by the fixture setup to be rolled back.$scenario$)
    );

end;
$$;

COMMIT;
