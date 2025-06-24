-- Deploy dream-db-extension:functions/_fail_test to pg

BEGIN;
--#region exclude_transaction

create function _fail_test(test_id integer, num integer, message text)
returns setof text
language plpgsql
as
$$
declare test_description text;
declare qualified_function text;
begin

    select
        test.description,
        format('%I.%I', test.schema, test.function)
    into
        test_description,
        qualified_function
    from test
    where test.id = test_id
    ;

    if not found then
        raise 'Test ID % not found. Cannot fail a test that does not exist.', test_id;
    end if;

    return query select _format_subtest(qualified_function, test_description);
    return query select _indent_lines(_comment_lines(message));
    return query select _indent_lines(_format_plan(0));
    return query select _format_result(false, num, qualified_function, test_description);

    update test_plan set ok = false where id = test_id;

end;
$$;

comment on function _fail_test(test_id integer, num integer, message text) is
$$Returns an empty subtest with a message describing the failure and sets the test's status to 'not ok'.
    test_id: The ID of the test in the test table.
    num: The test number to display in the subtest result.
    message: The message that describes the reason that the test failed.$$;

--#endregion exclude_transaction
COMMIT;
