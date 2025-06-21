-- Deploy dream-db-extension-tests:functions/execute_tests/delete-fixture-plan to pg

BEGIN;

create function unit_test.test_func_execute_tests__delete_fixture_plan()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When executing tests, if a fixture plan already exists, then the function shall delete that fixture plan.
$test_description$;
declare fixture_id_to_delete integer;
declare fixture_id_to_plan integer;
begin

    -- Add fixtures
    insert into fixture ("name") values ('my_fixture_to_delete') returning id into fixture_id_to_delete;
    insert into fixture ("name") values ('my_fixture_to_plan') returning id into fixture_id_to_plan;

    -- Add the fixture to the plan
    insert into fixture_plan("id") values (fixture_id_to_delete);

    perform execute_tests(array['my_fixture_to_plan'], null::name, null::text[]);
    return query select tap.set_hasnt(
        'select id from fixture_plan',
        format('values (%s)', fixture_id_to_delete),
        test_description
    );

end;
$$;

COMMIT;
