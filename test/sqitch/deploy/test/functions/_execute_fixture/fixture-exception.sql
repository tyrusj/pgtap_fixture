-- Deploy dream-db-extension-tests:test/functions/_execute_fixture/fixture-exception to pg

BEGIN;

create function unit_test.test_func_execute_fixture__fixture_exception()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When executing a fixture, if the fixture is not empty, and if the fixture throws an exception,
then the function shall return indented commented exception content.
$test_description$;
declare fixture_id_a integer;
declare fixture_id_b integer;
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

    -- create fixtures
    insert into fixture ("name", "shutdown")
    values (
        'fixture_a',
        $shutdown$select pg_temp._raise();$shutdown$
    )
    returning id into fixture_id_a;
    insert into fixture ("name", "parent_fixture_id") values ('fixture_b', fixture_id_a) returning id into fixture_id_b;

    -- add fixtures to the plan
    insert into fixture_plan ("id") values (fixture_id_a), (fixture_id_b);

    return query select tap.set_has(
        format('select _execute_fixture(%s, 1)', fixture_id_a),
        $want$values ('    # exception content')$want$,
        test_description
    );

end;
$$;

COMMIT;
