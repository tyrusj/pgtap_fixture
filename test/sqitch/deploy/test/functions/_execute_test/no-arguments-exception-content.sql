-- Deploy dream-db-extension-tests:test/functions/_execute_test/no-arguments-exception-content to pg

BEGIN;

create function unit_test.test_func_execute_test__no_arguments_exception_content()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When executing a test with data, if the test function does not take arguments, and if the test throws
an exception, then the function shall return indented commented exception content.
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

    alter function pgtap__set(text, integer)
    rename to pgtap__set___original;
    create function pgtap__set(text, integer)
    returns integer
    language plpgsql
    as
    $stub$
    begin
        return null;
    end;
    $stub$;
    
    alter function pgtap__get(text)
    rename to pgtap__get___original;
    create function pgtap__get(text)
    returns integer
    language plpgsql
    as
    $stub$
    begin
        return null;
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

    -- Mock _error_diag to ensure that it is called with the exception details.
    alter function _error_diag(errstate text, errmsg text, detail text, hint text, context text, schname text, tabname text, colname text, chkname text, typname text)
	rename to _error_diag___original;
	create function _error_diag(errstate text, errmsg text, detail text, hint text, context text, schname text, tabname text, colname text, chkname text, typname text)
	returns text
	language plpgsql
    as
    $mock$
	begin
		if errstate = 'ZZ123'
            and errmsg = 'message'
            and detail = 'detail'
            and hint = 'hint'
            and schname = 'schema'
            and tabname = 'table'
            and colname = 'column'
            and chkname = 'constraint'
            and typname = 'datatype' then
            return 'exception content';
        end if;
	end;
    $mock$;

    -- Create the test function
    create function pg_temp.my_test_function_with_args()
    returns setof text
    language plpgsql
    as
    $test$
    begin
        raise using
            message = 'message',
            detail = 'detail',
            hint = 'hint',
            errcode = 'ZZ123',
            column = 'column',
            constraint = 'constraint',
            datatype = 'datatype',
            table = 'table',
            schema = 'schema';
    end;
    $test$;

    -- Create the test
    insert into test ("schema", "function", "description") values ('pg_temp', 'my_test_function_with_args', 'my description args') returning id into test_id;

    -- Plan the tests
    insert into test_plan ("id") values (test_id);


    return query select tap.set_has(
        format('select _execute_test(%s, 1)', test_id),
        $want$values ('    # exception content')$want$,
        test_description
    );

end;
$$;

COMMIT;
