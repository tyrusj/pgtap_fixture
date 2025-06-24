-- Deploy dream-db-extension:functions/_execute_test_with_data/create to pg

BEGIN;
--#region exclude_transaction

create function _execute_test_with_data(
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
declare cursor_test_data scroll cursor for
    select parameters, description from test_data where test_data.test_id = _execute_test_with_data.test_id
;
declare test_datum record;
declare test_status boolean := true;
declare test_data_status boolean := true;
declare test_data_number integer := 0;
declare pgtap_tests integer := 0;
declare formatted_test_description text;
declare test_parameters jsonb;
begin

    open cursor_test_data;
    fetch first from cursor_test_data into test_datum;
    if not found then
        -- This test takes arguments but there is no data to execute the test with, therefore skip it.
        update test_plan set ok = test_status where id = test_id;
        return next _format_skip(test_status, num, qualified_function, test_description, 'No test data.');
    else
        -- This test takes arguments and has test data.

        return next _format_subtest(qualified_function, test_description);

        PERFORM * FROM pgtap_no_plan();

        fetch first from cursor_test_data into test_datum;
        while found
        loop
            test_data_number := test_data_number + 1;
            test_data_status := true;
            pgtap_tests := 0;

            -- Reset the test number used by pgtap tests.
            -- Copied from _runner(_text, _text, _text, _text, _text)
            perform pgtap__restart_numb_seq();
            perform pgtap__set('curr_test', 0);
            perform pgtap__set('failed', 0);

            begin
                -- Execute the test datum's parameters statement to get the parameters, or set the parameters to null.
                begin
                    if test_datum.parameters is not null then
                        execute test_datum.parameters into test_parameters;
                    else
                        test_parameters := null;
                    end if;
                exception
                    when others then
                        formatted_test_description := format(
                            E'Test description: %s\nTest data description: %s\nTest data: %s',
                            test_description,
                            test_datum.description,
                            null::jsonb
                        );
                        return query select _indent_lines(_format_subtest(qualified_function, formatted_test_description));
                        raise;
                end;

                formatted_test_description := format(
                    E'Test description: %s\nTest data description: %s\nTest data: %s',
                    test_description,
                    test_datum.description,
                    test_parameters
                );
                return query select _indent_lines(_format_subtest(qualified_function, formatted_test_description));

                if fixture_setup is not null then
                    execute fixture_setup;
                end if;

                begin
                    return query execute format('select _indent_lines(f.t, 2) from %s($1, $2) f(t);', qualified_function) using test_parameters, formatted_test_description;
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

                test_data_status := case when pgtap__get('failed') = 0 then true else false end;
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
                    )), 2);

                    test_data_status := false;
            end;

            return query select _indent_lines(_format_plan(pgtap_tests), 2);
            return query select _indent_lines(_format_result(test_data_status, test_data_number, qualified_function, formatted_test_description));

            test_status := test_status and test_data_status;

            fetch cursor_test_data into test_datum;
        end loop;
        close cursor_test_data;

        return query select _indent_lines(_format_plan(test_data_number));

        PERFORM pgtap__cleanup();
        
        return next _format_result(test_status, num, qualified_function, test_description);

        update test_plan set ok = test_status where id = test_id;
    end if;

end;
$$;

--#endregion exclude_transaction
COMMIT;
