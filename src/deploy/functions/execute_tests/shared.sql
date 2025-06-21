-- Deploy dream-db-extension:functions/execute_tests/create to pg

BEGIN;
--#region exclude_transaction

create function execute_tests(
    fixturePaths text[] default null::text[],
    testFunctionSchema name default null::name,
    testFunctions text[] default null::text[]
)
returns setof text
language plpgsql
as
$$
declare error_sqlstate text;
declare error_message_text text;
declare error_exception_detail text;
declare error_exception_hint text;
declare error_exception_context text;
declare error_schema_name text;
declare error_table_name text;
declare error_column_name text;
declare error_constraint_name text;
declare error_datatype_name text;
declare fixture_ids integer[] := array[]::integer[];
declare test_ids integer[] := array[]::integer[];
declare test_cursor refcursor;
declare test_record record;
declare fixture_cursor refcursor;
declare fixture_record record;
declare test_or_fixture_number integer := 0;
begin

    return next 'TAP Version 14';
    if array_length(fixturePaths, 1) is null and array_length(testFunctions, 1) is null then
        -- If no fixtures or tests are given, then get the IDs of the root tests and fixtures.
        select array_agg(id) from test where parent_fixture_id is null into test_ids;
        select array_agg(id) from fixture where parent_fixture_id is null into fixture_ids;
    else
        -- If tests or fixtures are given, then get the IDs of those tests and fixtures.
        open test_cursor for
        select t.func, test.id
        from unnest(testFunctions) t(func)
        left outer join test on test.function = t.func and test.schema = testFunctionSchema
        ;

        fetch test_cursor into test_record;
        while found
        loop
            if test_record.id is null then
                return next format('Bail Out! The test function %I.%I has not been added.', testFunctionSchema, test_record.func);
                close test_cursor;
                return;
            else
                test_ids := array_append(test_ids, test_record.id);
            end if;
            fetch test_cursor into test_record;
        end loop;
        close test_cursor;

        open fixture_cursor for
        select f.path, _get_fixture_by_path_and_root(f.path, null) id
        from unnest(fixturePaths) f(path)
        ;

        fetch fixture_cursor into fixture_record;
        while found
        loop
            if fixture_record.id is null then
                return next format('Bail Out! The fixture %s does not exist.', fixture_record.path);
                close fixture_cursor;
                return;
            else
                fixture_ids := array_append(fixture_ids, fixture_record.id);
            end if;
            fetch fixture_cursor into fixture_record;
        end loop;
        close fixture_cursor;

    end if;
    
    begin
        -- Delete and create the plan
        delete from test_plan;
        delete from fixture_plan;
        perform _plan_tests_and_fixtures(fixture_ids, test_ids);

        -- Execute the tests and fixtures in the plan that have no parent fixture
        for test_record in
            select test_plan.id
            from test_plan
            inner join test on test.id = test_plan.id
            where test.parent_fixture_id is null
        loop
            test_or_fixture_number := test_or_fixture_number + 1;
            return query select _execute_test(test_record.id, test_or_fixture_number);
        end loop;

        for fixture_record in
            select fixture_plan.id
            from fixture_plan
            inner join fixture on fixture.id = fixture_plan.id
            where fixture.parent_fixture_id is null
        loop
            test_or_fixture_number := test_or_fixture_number + 1;
            return query select _execute_fixture(fixture_record.id, test_or_fixture_number);
        end loop;

        return query select _format_plan(test_or_fixture_number);
    exception
        when others then
            return next 'Bail Out! Unhandled exception.';

            get stacked diagnostics
                error_sqlstate = returned_sqlstate,
                error_message_text = message_text,
                error_exception_detail = pg_exception_detail,
                error_exception_hint = pg_exception_hint,
                error_exception_context = pg_exception_context,
                error_schema_name = schema_name,
                error_table_name = table_name,
                error_column_name = column_name,
                error_constraint_name = constraint_name,
                error_datatype_name = pg_datatype_name
            ;

            return next _comment_lines(_error_diag(
                error_sqlstate,
                error_message_text,
                error_exception_detail,
                error_exception_hint,
                error_exception_context,
                error_schema_name,
                error_table_name,
                error_column_name,
                error_constraint_name,
                error_datatype_name
            ));
    end;

end;
$$;

comment on function execute_tests(
    fixturePaths text[],
    testFunctionSchema name,
    testFunctions text[]
) is
    $$Plans and executes all the given fixtures and tests. If no fixtures or tests are given, then all fixtures and tests will be planned and executed.
    Arguments:
        fixturePaths: The array of paths to the fixtures to execute.
        testFunctionSchema: The schema of the tests to execute.
        testFunctions: The array of test functions to execute.$$;

--#endregion exclude_transaction
COMMIT;
