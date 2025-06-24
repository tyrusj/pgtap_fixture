-- Deploy dream-db-extension:create-function-to-plan-parent-fixtures to pg

BEGIN;
--#region exclude_transaction

create function _plan_parent_fixtures(fixtureId integer)
returns void
language plpgsql
as
$$
declare fixture_exists integer;
begin
    -- If the fixture does not exist, then throw an exception.
    select id into fixture_exists
    from fixture
    where id = fixtureId
    ;
    if not found then
        raise 'Failed to plan fixture with ID "%". Fixture does not exist.', fixtureId;
    end if
    ;

    with recursive fixture_to_plan(id) as (
        -- Get the parent fixture of the given fixture if it has not already been planned.
        select fix.parent_fixture_id
        from fixture fix
        left outer join fixture_plan plan
        on plan.id = fix.parent_fixture_id
        where
            fix.id = fixtureId
            and fix.parent_fixture_id is not null
            and plan.id is null
        union
        -- Get the parent fixture of the previously retrieved parent fixture if it has not already been planned.
        select fix.parent_fixture_id
        from fixture fix
        inner join fixture_to_plan toplan
        on toplan.id = fix.id
        left outer join fixture_plan plan
        on plan.id = fix.parent_fixture_id
        where
            fix.parent_fixture_id is not null
            and plan.id is null
    )
    -- Add all of the parent fixtures to the plan.
    insert into fixture_plan (id) select id from fixture_to_plan
    ;

end;
$$;

comment on function _plan_parent_fixtures(fixtureId integer) is
    $$Plans the fixture that is the parent of the given fixture. This function will recursively plan parent fixtures until a fixture is reached with no parent. No tests are planned, only the fixtures. Note, the given fixture itself is NOT planned.
    Arguments:
        fixtureId: The id of the fixture in the fixture table whose parent fixtures should be planned.$$;

--#endregion exclude_transaction
COMMIT;
