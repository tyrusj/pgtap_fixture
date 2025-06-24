-- Deploy dream-db-extension:functions/_execute_test_without_data/create to pg

BEGIN;
--#region exclude_transaction

create function _execute_test_without_data(
    test_id integer,
    num integer,
    qualified_function text,
    test_description text,
    fixture_setup text,
    fixture_teardown text
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
declare test_status boolean := true;
declare pgtap_tests integer := 0;
begin
    
    return next _format_subtest(qualified_function, test_description);

    PERFORM * FROM pgtap_no_plan();

    -- Reset the test number used by pgtap tests.
    -- Copied from _runner(_text, _text, _text, _text, _text)
    perform pgtap__restart_numb_seq();
    perform pgtap__set('curr_test', 0);
    perform pgtap__set('failed', 0);

    begin
        if fixture_setup is not null then
            execute fixture_setup;
        end if;

        begin
            -- Execute the test function and indent its result lines.
            return query execute format('select _indent_lines(f.t) from %s() f(t);', qualified_function);

            pgtap_tests := pgtap__get('curr_test');
        exception
            when others then
                -- Always teardown, even if the test threw an exception.
                if fixture_teardown is not null then
                    execute fixture_teardown;
                end if;
                raise;
        end;
        
        if fixture_teardown is not null then
            execute fixture_teardown;
        end if;

        test_status := case when pgtap__get('failed') = 0 then true else false end;
        perform _function_rollback();
    exception
        when sqlstate 'TJ1A0' then
            -- Do nothing. This exception forces intentional rollback.
        when others then
            get stacked diagnostics
                error_sqlstate := returned_sqlstate,
                error_message_text := message_text,
                error_exception_detail := pg_exception_detail,
                error_exception_hint := pg_exception_hint,
                error_exception_context := pg_exception_context,
                error_schema_name := schema_name,
                error_table_name := table_name,
                error_column_name := column_name,
                error_constraint_name := constraint_name,
                error_datatype_name := pg_datatype_name
            ;

            return query select _indent_lines(_comment_lines(_error_diag(
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

            test_status := false;
    end;

    return query select _indent_lines(_format_plan(pgtap_tests));

    PERFORM pgtap__cleanup();
    
    return next _format_result(test_status, num, qualified_function, test_description);

    update test_plan set ok = test_status where id = test_id;
end;
$$;

--#endregion exclude_transaction
COMMIT;
