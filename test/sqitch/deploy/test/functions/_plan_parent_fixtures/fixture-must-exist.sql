-- Deploy dream-db-extension-tests:func-plan-parent-fixtures-fixture-must-exist to pg

BEGIN;

create function unit_test.test_func_plan_parent_fixtures__fixture_must_exist()
returns setof text
language plpgsql
as
$$
declare test_description text :=$description$
When planning parent fixtures, if the given fixture does not exist, then the database shall throw an exception.
$description$;
declare fixture_exists integer;
declare fixture_id_does_not_exist integer;
begin
    -- Insert a new fixture and store its ID
    insert into fixture ("name")
    values ('my_fixture')
    returning id into fixture_id_does_not_exist
    ;

    insert into fixture ("name")
    values ('my_fixture_2')
    returning id into fixture_exists
    ;

    -- Delete that fixture. Now the fixture with that ID is guaranteed to not exist.
    delete from fixture
    where id = fixture_id_does_not_exist
    ;

    return query select tap.throws_ok
    (
        format($throws$select _plan_parent_fixtures(%s)$throws$, fixture_id_does_not_exist),
        null,
        format(
            E'%s\ntest_scenario: %s', test_description,
			$scenario$1: Plan parents of a fixture that does not exist. Expect exception.$scenario$
        )
    );

    return query select tap.lives_ok
    (
        format($throws$select _plan_parent_fixtures(%s)$throws$, fixture_exists),
        format(
            E'%s\ntest_scenario: %s', test_description,
			$scenario$2: Plan parents of a fixture that does exist. Expect no exception.$scenario$
        )
    );

end;
$$;
COMMIT;
