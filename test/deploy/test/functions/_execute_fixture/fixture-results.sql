-- Deploy dream-db-extension-tests:test/functions/_execute_fixture/fixture-results to pg

BEGIN;

create function unit_test.test_func_execute_fixture__fixture_results()
returns setof text
language plpgsql
as
$$
declare test_description text := $test_description$
When executing a fixture, if the fixture contains child fixtures, then the function shall indent
and return the results of each child fixture.
$test_description$;
declare fixture_id_a integer;
declare fixture_id_b integer;
declare fixture_id_c integer;
begin

    -- Setup _execute_fixture to output specified results
    alter function _execute_fixture(fixtureId integer, num integer)
    rename to _execute_fixture___original;
    create function _execute_fixture(fixtureId integer, num integer)
    returns setof text
    language plpgsql
    as
    $setup$
    declare fixture_name text;
    begin
        select name into fixture_name
        from fixture
        where fixture.id = fixtureId
        ;
        if fixture_name = 'fixture_b' then
            return next 'fixture results: fixture_b';
        elsif fixture_name = 'fixture_c' then
            return next 'fixture results: fixture_c';
        else
            return query select _execute_fixture___original(fixtureId, num);
        end if;
    end;
    $setup$;

    -- create fixtures
    insert into fixture ("name") values ('fixture_a') returning id into fixture_id_a;
    insert into fixture ("name", "parent_fixture_id") values ('fixture_b', fixture_id_a) returning id into fixture_id_b;
    insert into fixture ("name", "parent_fixture_id") values ('fixture_c', fixture_id_a) returning id into fixture_id_c;

    -- add fixtures to the plan
    insert into fixture_plan ("id") values (fixture_id_a), (fixture_id_b), (fixture_id_c);

    return query select tap.set_has(
        format('select _execute_fixture(%s, 1)', fixture_id_a),
        $want$values ('    fixture results: fixture_b'), ('    fixture results: fixture_c')$want$,
        test_description
    );

end;
$$;

COMMIT;
