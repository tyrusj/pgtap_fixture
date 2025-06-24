-- Deploy dream-db-extension-tests:functions/_execute_fixture/shutdown-on-test-exception to pg

BEGIN;

create function unit_test.test_func_execute_fixture__shutdown_on_test_exception()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When executing a fixture, if a child test throws an exception, then the function shall execute the fixture's
shutdown statement.
$test_description$;
declare fixture_id integer;
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

    -- Create a test function
    create function pg_temp.my_function()
    returns setof text
    language plpgsql
    as
    $test$
    begin
        raise 'Child test exception.';
    end;
    $test$;

    -- Create a sequence and initialize it.
    create temp sequence my_seq;
    perform nextval('my_seq');

    insert into fixture ("name", "startup", "shutdown") values (
        'my_fixture',
        $startup$select setval('my_seq', 100);$startup$,
        $shutdown$select setval('my_seq', 200);$shutdown$
    )
    returning id into fixture_id;

    -- Create tests
    insert into test ("schema", "function", "parent_fixture_id") values ('pg_temp', 'my_function', fixture_id) returning id into test_id;

    -- Add to the plan
    insert into fixture_plan ("id") values (fixture_id);
    insert into test_plan ("id") values (test_id);

    -- Execute the scenarios

    perform _execute_fixture(fixture_id, 1);
    return query select tap.is(
        currval('my_seq'),
        200::bigint,
        test_description
    );

end;
$$;

COMMIT;
