-- Deploy dream-db-extension:create-function-to-execute-fixture to pg

BEGIN;
--#region exclude_transaction

create function _execute_fixture(fixtureId integer, num integer)
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
declare fixture_id_exists integer;
declare parent_fixture_setup text;
declare parent_fixture_teardown text;
declare fixture_startup text;
declare fixture_shutdown text;
declare test_record record;
declare fixture_record record;
declare test_cursor scroll cursor for
    select
        test.id,
        format('%I.%I', test.schema, test.function) as "name",
        test.description
    from test
    inner join test_plan on test_plan.id = test.id
    where test.parent_fixture_id = fixtureId
    ;
declare fixture_cursor scroll cursor for
    select
        fixture.id,
        _get_fixture_path(fixture.id) as "name",
        fixture.description
    from fixture
    inner join fixture_plan on fixture_plan.id = fixture.id
    where fixture.parent_fixture_id = fixtureId
    ;
declare test_or_fixture_number integer := 0;
declare fixture_path text;
declare fixture_description text;
declare fixture_status boolean := true;
begin
    -- Throw an exception if the fixture does not exist.
    select id into fixture_id_exists
    from fixture
    where id = fixtureId
    ;
    if not found then
        raise 'Failed to execute fixture with ID "%". Fixture does not exist', fixtureId;
    end if;

    -- Get the setup, teardown, startup, and shutdown statements to execute and other info about the fixture.
    select
        parent.setup,
        parent.teardown,
        child.startup,
        child.shutdown,
        child.description,
        _get_fixture_path(child.id)
    into
        parent_fixture_setup,
        parent_fixture_teardown,
        fixture_startup,
        fixture_shutdown,
        fixture_description,
        fixture_path
    from fixture child
    left outer join fixture parent on parent.id = child.parent_fixture_id
    where child.id = fixtureId
    ;
    
    -- Get the first test and fixture to verify whether the fixture is empty.
    open test_cursor;
    open fixture_cursor;
    fetch first from test_cursor into test_record;
    fetch first from fixture_cursor into fixture_record;

    if test_record is null and fixture_record is null then
        -- The fixture is empty. Skip this fixture.
        update fixture_plan set ok = fixture_status where id = fixtureId;
        return next _format_skip(fixture_status, num, fixture_path, fixture_description, 'Fixture is empty.');
    else
        -- The fixture is not empty.
        return next _format_subtest(fixture_path, fixture_description);

        begin
            if parent_fixture_setup is not null then
                execute parent_fixture_setup;
            end if;

            begin
                if fixture_startup is not null then
                    execute fixture_startup;
                end if;
            exception
                when others then
                    -- Always teardown the parent fixture, even if the fixture throws an exception
                    if parent_fixture_teardown is not null then
                        execute parent_fixture_teardown;
                    end if;
                    raise;
            end;
            
            -- Execute each test in the fixture that is in the test plan.
            fetch first from test_cursor into test_record;
            while found
            loop
                test_or_fixture_number := test_or_fixture_number + 1;

                -- Indent the results of each test.
                return query
                select _indent_lines(results.tap)
                from _execute_test(test_record.id, test_or_fixture_number) results(tap)
                ;

                -- If the test failed, then set the fixture's status to false (not ok).
                select fixture_status and test_plan.ok into fixture_status from test_plan where test_plan.id = test_record.id;

                fetch next from test_cursor into test_record;
            end loop;
            close test_cursor;

            -- Execute each child fixture that is in the fixture plan.
            fetch first from fixture_cursor into fixture_record;
            while found
            loop
                test_or_fixture_number := test_or_fixture_number + 1;
                
                -- Indent the results of each fixture.
                return query
                select _indent_lines(results.tap)
                from _execute_fixture(fixture_record.id, test_or_fixture_number) results(tap)
                ;
                
                -- If the child fixture failed, then set the fixture's status to false (not ok).
                select fixture_status and fixture_plan.ok into fixture_status from fixture_plan where fixture_plan.id = fixture_record.id;

                fetch next from fixture_cursor into fixture_record;
            end loop;
            close fixture_cursor;

            begin
                if fixture_shutdown is not null then
                    execute fixture_shutdown;
                end if;
            exception
                when others then
                    -- Always teardown the parent fixture, even if the fixture throws an exception
                    if parent_fixture_teardown is not null then
                        execute parent_fixture_teardown;
                    end if;
                    raise;
            end;

            if parent_fixture_teardown is not null then
                execute parent_fixture_teardown;
            end if;

            perform _function_rollback();
        exception
            when sqlstate 'TJ1A0' then
                -- Do nothing. This exception forces intentional rollback.
            when others then
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

                return next _indent_lines(_comment_lines(_error_diag(
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
                )));

                fixture_status := false;        
        end;
        
        update fixture_plan set ok = fixture_status where id = fixtureId;

        return next _indent_lines(_format_plan(test_or_fixture_number));
        return next _format_result(fixture_status, num, fixture_path, fixture_description);
    end if;
end;
$$;

comment on function _execute_fixture(fixtureId integer, num integer) is
    $$Executes all tests and child fixtures in the given fixture. The fixture's startup statement is executed once before any child tests and fixtures are executed, and the fixture's shutdown statement is executed after all child tests and fixtures are executed. If the given fixture is contained within a parent fixture, then the parent fixture's setup statement is executed before the startup, and the parent fixture's teardown statement is executed after the shutdown.
    Arguments:
        fixtureId: The id of a record from the fixture table.
        num: The number of this fixture (which is a TAP subtest). This will be included in the return value in accordance with the TAP specification.$$;

--#endregion exclude_transaction
COMMIT;
