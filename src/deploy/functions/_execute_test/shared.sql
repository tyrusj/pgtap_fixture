-- Deploy dream-db-extension:create-function-to-execute-tests-with-data to pg

BEGIN;
--#region exclude_transaction

create function _execute_test(testId integer, num integer)
returns setof text
language plpgsql
as
$$
declare test_id_exists integer;
declare test_function_args text[];
declare test_function_return_type text;
declare test_function_return_set boolean;
declare test_function_args_too_many text[];
declare cursor_test_function_args refcursor;
declare test_description text;
declare test_schema name;
declare test_function name;
declare fixture_setup text;
declare fixture_teardown text;
declare qualified_function text;
begin
    -- Throw an exception if the test does not exist.
    select id into test_id_exists
    from test
    where id = testId
    ;
    if not found then
        raise 'Failed to execute test with ID "%". Test does not exist', testId;
    end if
    ;

    -- Get the information about the test and its parent fixture, if any.
    select
        test.description,
        test.schema,
        test.function,
        format('%I.%I', test.schema, test.function) "name",
        fixture.setup,
        fixture.teardown
    into
        test_description,
        test_schema,
        test_function,
        qualified_function,
        fixture_setup,
        fixture_teardown
    from test
    left outer join fixture on fixture.id = test.parent_fixture_id
    where test.id = testId
    ;

    -- Get the function arguments for the given test as an array of text
    open cursor_test_function_args for
    select
        array_agg(arg) args,
        proretset,
        prorettype
    from (
        select
            typ.typname::text arg,
            ns.nspname,
            proc.proname,
            proc.proargtypes,
            proc.proretset,
            proc.prorettype::regtype::text
        from pg_catalog.pg_proc proc
        inner join pg_catalog.pg_namespace ns on ns.oid = proc.pronamespace
        left outer join lateral unnest(proc.proargtypes) with ordinality argtyp(oid, idx) on true
        left outer join pg_catalog.pg_type typ on typ.oid = argtyp.oid
        where
            case
                when test_schema = 'pg_temp' then ns.oid = pg_my_temp_schema()
                else ns.nspname = test_schema
            end
            and proc.proname = test_function
        order by ns.nspname, proc.proname, proc.proargtypes, proc.proretset, proc.prorettype, argtyp.idx
    )
    group by nspname, proname, proargtypes, proretset, prorettype
    ;

    fetch cursor_test_function_args into test_function_args, test_function_return_set, test_function_return_type;
    if not found then
        return query select _fail_test(testId, num, format('Test function named %s was not found.', qualified_function));
        close cursor_test_function_args;
        return;
    end if;
    fetch cursor_test_function_args into test_function_args_too_many;
    if found then
        return query select _fail_test(testId, num, format('Multiple functions named %s were found. Cannot determine which one to execute. Please drop all but one function with that schema and name.', qualified_function));
        close cursor_test_function_args;
        return;
    end if;
    close cursor_test_function_args;

    if not test_function_return_set then
        return query select _fail_test(testId, num, format('Test function named %s does not return setof text. Found return type: %s', qualified_function, test_function_return_type));
        return;
    end if;

    if test_function_return_type != 'text' then
        return query select _fail_test(testId, num, format('Test function named %s does not return setof text. Found return type: setof %s', qualified_function, test_function_return_type));
        return;
    end if;
    
    if test_function_args = array[null] then
        -- The test function takes no arguments
        return query select _execute_test_without_data(testId, num, qualified_function, test_description, fixture_setup, fixture_teardown);
    elsif test_function_args = array['jsonb', 'text'] then
        -- The test function takes two arguments: parameters jsonb, description text
        return query select _execute_test_with_data(testId, num, qualified_function, test_description, fixture_setup, fixture_teardown);
    else
        return query select _fail_test(testId, num, format('The test function named %1$L has an invalid signature "%2$s". Change the function to one of the following:
create function %1$L() returns setof text
create function %1$L(parameters jsonb, description text) returns setof text', qualified_function, array_to_string(test_function_args, ',', 'null')));
        return;
    end if;

end;
$$;

comment on function _execute_test(testId integer, num integer) is
    $$Execute the given test. If there are records in the test_data table that correspond with this test, then the test is executed with each of those test data. If the test is in a fixture, then the fixture setup is executed before each test execution, and the fixture teardown is executed after each test execution.
    Arguments:
        testId: The id of a record from the test table.
        num: The number of this test (which is a TAP subtest). This will be included in the return value in accordance with the TAP specification.$$;

--#endregion exclude_transaction
COMMIT;
