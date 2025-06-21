-- Deploy dream-db-extension:functions/_get_fixture_path/create to pg

BEGIN;
--#region exclude_transaction

create function _get_fixture_path(fixture_id integer)
returns text
language sql
stable parallel safe strict
begin atomic
    -- Loop through the parent fixtures of the given fixture, and prepend the their names to the path,
    -- separated by slashes.
    with recursive child(parent_id, path, idx) as (
        select parent_fixture_id, name, 1 from fixture where id = fixture_id
        union
        select
            fixture.parent_fixture_id,
            fixture.name || '/' || child.path,
            child.idx + 1
        from child, fixture
        where
            fixture.id = child.parent_id
    )
    select last_value(child.path) over (order by child.idx desc) from child;
end;

comment on function _get_fixture_path(fixture_id integer) is
    'Assembles the fixture path for the given fixture ID into the form "path/to/given/fixture". Each segment of the path is the name of a fixture.';

--#endregion exclude_transaction
COMMIT;
