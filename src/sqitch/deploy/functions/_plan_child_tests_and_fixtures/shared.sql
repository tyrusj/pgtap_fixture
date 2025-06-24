-- Deploy dream-db-extension:create-function-to-plan-child-tests-and-fixtures to pg

BEGIN;
--#region exclude_transaction

create function _plan_child_tests_and_fixtures(fixtureId integer)
returns void
language plpgsql
as
$$
declare fixture_id_exists integer;
declare fixtures_to_plan integer[];
begin
    -- Throw an exception if the fixture does not exist.
    select id into fixture_id_exists
    from fixture
    where id = fixtureId
    ;
    if not found then
        raise 'Failed to plan fixture with ID "%". Fixture does not exist', fixtureId;
    end if
    ;
    
    -- Add tests from the fixture to the test plan if they are not already in the test plan.
    insert into test_plan (id)
    select tst.id
    from test tst
    left outer join test_plan plan
    on tst.id = plan.id
    where
        tst.parent_fixture_id = fixtureId
        and plan.id is null
    ;

    -- Get the IDs of the child fixtures that haven't been planned yet.
    -- Store them in an array instead of a table, because this function is called recursively.
    fixtures_to_plan := array(
        select fix.id
        from fixture fix
        left outer join fixture_plan plan
        on fix.id = plan.id
        where
            fix.parent_fixture_id = fixtureId
            and plan.id is null
    );

    -- Add the child fixtures to the plan.
    insert into fixture_plan (id) select p.id from unnest(fixtures_to_plan) as p(id)
    ;

    -- Recursively plan the child tests and fixtures of the child fixtures just planned.
    perform _plan_child_tests_and_fixtures(p.id) from unnest(fixtures_to_plan) as p(id)
    ;

end;
$$;

comment on function _plan_child_tests_and_fixtures(fixtureId integer) is
    $$Plans tests and fixtures that are contained in the given fixture. This function recursively plans tests and fixtures that are in child fixtures of the given fixture. Note, the given fixture itself is NOT planned.
    Arguments:
        fixtureId: The id of the fixture in the fixture table whose child tests and fixtures should be planned.$$;

--#endregion exclude_transaction
COMMIT;
