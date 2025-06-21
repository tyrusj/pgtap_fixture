-- Deploy dream-db-extension-tests:test/functions/execute_tests/exception-content to pg

BEGIN;

create function unit_test.test_func_execute_tests__exception_content()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When executing tests, if an exception is thrown, then the function shall return commented exception content.
$test_description$;
begin

    -- Create a function to raise an exception, since I can't raise from within dynamic SQL
    create function pg_temp._raise()
    returns void
    language plpgsql
    as
    $raise$
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
    $raise$;

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
        else
            raise notice 'error_diag: %', _error_diag___original(errstate, errmsg, detail, hint, context, schname, tabname, colname, chkname, typname);
            return '';
        end if;
	end;
    $mock$;

    -- Mock _execute_test to throw an exception
    alter function _execute_test(testId integer, num integer)
    rename to _execute_test___original;
    create function _execute_test(testId integer, num integer)
    returns setof text
    language plpgsql
    as
    $mock$
    begin
        perform pg_temp._raise();
        return next '';
    end;
    $mock$;

    -- Create a test
    insert into test ("schema", "function") values ('my_schema', 'my_function');

    return query select tap.set_has(
        'select execute_tests(null, null, null)',
        $want$values ('# exception content')$want$,
        test_description
    );

end;
$$;

COMMIT;
