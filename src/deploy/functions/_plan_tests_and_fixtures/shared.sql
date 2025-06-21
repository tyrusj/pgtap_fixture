-- Deploy dream-db-extension:create-function-to-plan-tests-and-fixtures to pg

BEGIN;
--#region exclude_transaction

create function _plan_tests_and_fixtures(fixtureIds integer[], testIds integer[])
returns void
language plpgsql
as
$$
declare null_fixtures_count integer;
declare null_tests_count integer;
declare missing_fixtures text;
declare missing_tests text;
begin

    -- Fail if any fixtures are null
    select count(*)
    from unnest(fixtureIds) arg(id)
    where arg.id is null
    into null_fixtures_count
    ;
    if null_fixtures_count > 0 then
        raise 'The array of fixture IDs contains nulls. Cannot plan tests and fixtures.';
    end if;

    -- Fail if any tests are null
    select count(*)
    from unnest(testIds) arg(id)
    where arg.id is null
    into null_tests_count
    ;
    if null_tests_count > 0 then
        raise 'The array of test IDs contains nulls. Cannot plan tests and fixtures.';
    end if;

    -- Fail if any fixtures don't exist
    select string_agg(arg.id::text, ', ')
    from unnest(fixtureIds) arg(id)
    left outer join fixture fix
    on fix.id = arg.id
    where fix.id is null
    into missing_fixtures
    ;
    if missing_fixtures is not null then
        raise 'Cannot plan fixtures that do not exist. Missing fixture IDs: %', missing_fixtures;
    end if
    ;
    -- Fail if any tests don't exist.
    select string_agg(arg.id::text, ', ')
    from unnest(testIds) arg(id)
    left outer join test tst
    on tst.id = arg.id
    where tst.id is null
    into missing_tests
    ;
    if missing_tests is not null then
        raise 'Cannot plan tests that do not exist. Missing test IDs: %', missing_fixtures;
    end if
    ;

    -- Add tests to the plan if they are not already in the plan.
    insert into test_plan
    select test.id
    from unnest(testIds) test(id)
    left outer join test_plan plan
    on plan.id = test.id
    where plan.id is null
    ;

    -- Add fixtures to the plan if they are not already in the plan.
    insert into fixture_plan
    select fixture.id
    from unnest(fixtureIds) fixture(id)
    left outer join fixture_plan plan
    on plan.id = fixture.id
    where plan.id is null
    ;

    -- Add each test's parent fixture to the plan if it is not already in the plan
    insert into fixture_plan
    select test.parent_fixture_id
    from unnest(testIds) arg(id)
    inner join test
    on test.id = arg.id
    left outer join fixture_plan plan
    on plan.id = test.parent_fixture_id
    where
        plan.id is null
        and test.parent_fixture_id is not null
    ;

    -- Recursively add the parent fixtures of each test to the plan.
    perform _plan_parent_fixtures(test.parent_fixture_id)
    from unnest(testIds) arg(id)
    inner join test
    on test.id = arg.id
    where test.parent_fixture_id is not null
    ;

    -- Recursively add the parent fixtures of each fixture to the plan.
    perform _plan_parent_fixtures(fix.id)
    from unnest(fixtureIds) fix(id)
    ;

    -- Recursively add the child tests and fixtures of each fixture to the plan.
    perform _plan_child_tests_and_fixtures(fix.id)
    from unnest(fixtureIds) fix(id)
    ;

end;
$$;

comment on function _plan_tests_and_fixtures(fixtureIds integer[], testIds integer[]) is
    $$Plans all the given fixtures and tests. This function also plans child tests and fixtures of the given fixtures as well as parent fixtures of the given tests and fixtures. The result is a complete plan that is ready to execute.
    Arguments:
        fixtureIds: The ids of fixtures from the fixture table that should be planned.
        testIds: The ids of tests from the test table that should be planned.$$;

--#endregion exclude_transaction
COMMIT;
