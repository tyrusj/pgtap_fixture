-- Deploy dream-db-extension-tests:functions/_execute_test/set-test-description to pg

BEGIN;

create function unit_test.test_func_execute_test__set_test_description()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When executing a test with data, for each record in the test data table that corresponds with the given
test, the function shall execute the test with a test description value that is a combination of the test
record's description, the test data record's description, and the result of the test data's parameters
statement.
$test_description$;
declare test_id integer;
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

    -- Stub the rollback function, so that changes aren't automatically rolled back.
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

    -- Create a table where the test description that a test is executed with will be stored.
    create temp table executed_test_descriptions(test_description text);

    -- Create test functions
    create function pg_temp.my_test_function_a(parameters jsonb, testDescription text)
    returns setof text
    language plpgsql
    as
    $test$
    begin
        insert into executed_test_descriptions ("test_description") values (testDescription);
    end;
    $test$
    ;

    -- Create a test record
    insert into test ("schema", "function", "description") values ('pg_temp', 'my_test_function_a', 'A') returning id into test_id;

    -- Create test data
    insert into test_data ("test_id", "description", "parameters") values (test_id, '1', $params$select '["params1"]';$params$);
    insert into test_data ("test_id", "description", "parameters") values (test_id, '2', $params$select '["params2"]';$params$);

    -- Plan the test
    insert into test_plan ("id") values (test_id);

    -- Execute the scenario

    perform _execute_test(test_id, 1);
    return query select tap.set_has(
        'select test_description from executed_test_descriptions',
        $has$
        select v.description
        from (values
            (E'Test description: A\nTest data description: 1\nTest data: ["params1"]'),
            (E'Test description: A\nTest data description: 2\nTest data: ["params2"]')
        ) v(description)
        $has$,
        test_description
    );

end;
$$;

COMMIT;
